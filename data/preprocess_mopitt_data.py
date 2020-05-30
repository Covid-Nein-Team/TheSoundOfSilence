import os
import csv
import h5py
from shapely.geometry import Point, Polygon, asPolygon
import json
import re
from tqdm import tqdm

# This file processes MOPITT carbon monoxide measurements
# ( https://www2.acom.ucar.edu/mopitt )
# In particular, we read the raw data as provided by
# https://earthdata.nasa.gov/ in HE 5 format and transform it to a CSV
# file with time (in days) on the y axis and countries on the x axis.
# The matching from MOPITT geolocations to countries is performed using an
# auxiliary geojson file.

GEOJSON_FILE = '../resources/countries.geojson'
OUT_FILE = 'mopitt_data.csv'

date_pattern = re.compile('(20\d{2})(\d{2})(\d{2})')

# load the polygons for all countries from the geojson file
country_to_polygons = {}

with open(GEOJSON_FILE) as geojson_file:
    geojson = json.load(geojson_file)
    for country_json in geojson['features']:
        country = country_json['properties']['name']
        polygons = []
        if country_json['geometry']['type'] == 'Polygon':
            polygon = []
            for point in country_json['geometry']['coordinates'][0]:
                polygon.append((point[0], point[1]))
            polygon = Polygon(polygon)
            polygons.append(polygon)
        elif country_json['geometry']['type'] == 'MultiPolygon':
            for json_polygon in country_json['geometry']['coordinates']:
                polygon = []
                for point in json_polygon[0]:
                    polygon.append((point[0], point[1]))
                polygon = Polygon(polygon)
                polygons.append(polygon)
        else:
            raise ValueError('Unknown geometry type: %s' % country_json['geometry']['type'] )
        country_to_polygons[country] = polygons

# set up the list of all he5 files in the current directory
he5_files = []
for f in os.listdir("."):
    if f.endswith(".he5"):
        he5_files.append(f)
he5_files.sort()

# initialize output lists
out_data = []
dates    = []

# iterate over all MOPITT files
for he5_file in he5_files:
    date = date_pattern.search(he5_file)
    date = '%s-%s-%s' % (date.groups()[0], date.groups()[1], date.groups()[2])
    dates.append(date)
    print('--- processing date %s ---' % date)

    country_to_value = {}
    country_to_count = {}

    with h5py.File(he5_file, 'r') as f:
        # retrieve longitudes and latitudes for the grid
        lons = f['HDFEOS']['GRIDS']['MOP03']['Data Fields']['Longitude']
        lats = f['HDFEOS']['GRIDS']['MOP03']['Data Fields']['Latitude']
        # retrieve the data grid itself
        CO   = f['HDFEOS']['GRIDS']['MOP03']['Data Fields']['RetrievedCOTotalColumnDay']
        # iterate over all entries in the grid
        last_country = None
        for i in tqdm(range(len(lons))):
            for j in range(len(lats)):
                point = Point(lons[i], lats[j])
                matched_country = None
                # exclude invalid values (-9999)
                if CO[i][j] < -1000:
                    continue
                # check first if we are in the same country as before
                if last_country is not None:
                    for polygon in country_to_polygons[last_country]:
                        if polygon.contains(point):
                            matched_country = country
                            break
                # otherwise check all countries
                if matched_country is None:
                    for country in country_to_polygons:
                        if country == last_country:
                            continue
                        for polygon in country_to_polygons[country]:
                            if polygon.contains(point):
                                matched_country = country
                                break
                        if matched_country is not None:
                            break
                if matched_country is None:
                    continue
                # add the value to the country
                country_to_value.setdefault(matched_country, 0.)
                country_to_count.setdefault(matched_country, 0)
                country_to_value[matched_country] += CO[i][j]
                country_to_count[matched_country] += 1
                last_country = matched_country

    # normalize all country values by count and divide by 1E18 to have a
    # more 'civil' data range
    for country in country_to_value:
        country_to_value[country] /= country_to_count[country]
        country_to_value[country] *= 1E-18

    # append to output
    out_data.append(country_to_value)

# create a sorted list of countries
countries = list(sorted(country_to_polygons.keys()))

# generate output file
with open(OUT_FILE, 'w', newline='') as csvfile:
    writer = csv.writer(csvfile, delimiter=',', quotechar='\"', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(['date'] + countries)
    for i in range(len(dates)):
        row = [dates[i]]
        for country in countries:
            if country in out_data[i]:
                row.append(out_data[i][country])
            else:
                row.append(float('nan'))
        writer.writerow(row)
