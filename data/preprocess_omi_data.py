import os
import csv
import numpy as np
import h5py
from shapely.geometry import Point, Polygon, asPolygon
import json
import re
from tqdm import tqdm

# This file processes OMI Nitrogen dioxide (NO2) measurements
# ( https://aura.gsfc.nasa.gov/omi.html )
# In particular, we read the raw data as provided by
# https://earthdata.nasa.gov/ in HE 5 format and transform it to a CSV
# file with time (in days) on the y axis and countries on the x axis.
# The matching from OMI geolocations to countries is performed using an
# auxiliary geojson file.

GEOJSON_FILE = '../resources/countries.geojson'
OUT_FILE = 'no2_data.csv'

date_pattern = re.compile('(20\d{2})m(\d{2})(\d{2})')

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

# create a sorted list of countries
countries = list(sorted(country_to_polygons.keys()))

# since the grid of the OMI measurements is stable over time, we can pre-compute
# the assignment from countries to geographic regions
lats = np.arange(-90., 90., 0.25)
lons = np.arange(-180., 180., 0.25)

# initialize a mask for each country
country_to_mask = {}
for country in countries:
    country_to_mask[country] = np.zeros((len(lats), len(lons)))

# now, iterate over each grid point and check in which country it is
print('setting up geographic mask for each country')
last_country = None
for i in tqdm(range(len(lats))):
    for j in range(len(lons)):
        point = Point(lons[j], lats[i])
        # check first if we are in the same country as before
        found_country = False
        if last_country is not None:
            for polygon in country_to_polygons[last_country]:
                if polygon.contains(point):
                    country_to_mask[last_country][i, j] = 1.
                    found_country = True
                    break
        # otherwise check all countries
        if not found_country:
            for country in country_to_polygons:
                if country == last_country:
                    continue
                for polygon in country_to_polygons[country]:
                    if polygon.contains(point):
                        country_to_mask[country][i, j] = 1.
                        found_country = True
                        last_country = country
                        break
                if found_country:
                    break

if False:
    # for debug-purposes: show a few masks
    import matplotlib.pyplot as plt
    plt.imshow(country_to_mask['Germany'] + country_to_mask['Australia'] + country_to_mask['Netherlands'])
    plt.show()

print('finished geographic masks; starting to process OMI raw data')

# set up the list of all he5 files in the current directory
he5_files = []
for f in os.listdir("omi_raw_data"):
    if f.endswith(".he5"):
        he5_files.append(f)
he5_files.sort()

# initialize output lists
out_data = []
dates    = []

# iterate over all OMI files
for he5_file in he5_files:
    date = date_pattern.search(he5_file)
    date = '%s-%s-%s' % (date.groups()[0], date.groups()[1], date.groups()[2])
    dates.append(date)
    print('--- processing date %s ---' % date)

    country_to_value = {}

    with h5py.File("omi_raw_data/" + he5_file, 'r') as f:
        # retrieve NO2 measurements
        NO2 = np.array(f['HDFEOS']['GRIDS']['ColumnAmountNO2']['Data Fields']['ColumnAmountNO2'])
        # get the mask for missing values
        valid = NO2 > 0.

        # iterate over all countries and mask out the matching values
        for c in tqdm(range(len(countries))):
            country = countries[c]
            mask = country_to_mask[country]
            # check if there are any non-missing values in the country mask
            if np.sum(mask[valid] > 0.5):
                # if so, take the average value over the mask
                country_to_value[country] = np.mean(mask[valid] * NO2[valid])
            else:
                country_to_value[country] = float('nan')

    # append to output
    out_data.append(country_to_value)

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
