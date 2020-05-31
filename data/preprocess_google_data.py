import csv
import numpy as np
import json

# preprocesses data from the Global_Mobility_Report.csv as provided by Google
# under https://www.google.com/covid19/mobility/
#
# The expected data format is, for each row:
# 
# country_region_code,country_region,sub_region_1,sub_region_2,date,retail_and_recreation_percent_change_from_baseline,grocery_and_pharmacy_percent_change_from_baseline,parks_percent_change_from_baseline,transit_stations_percent_change_from_baseline,workplaces_percent_change_from_baseline,residential_percent_change_from_baseline
#
# We transform this into a table with dates on the y axis, countries on the
# x axis, and a general activity level in each cell, which is the sum of all
# activity values in the last columns of the table.

DATE_COL = 4
COUNTRY_COL = 1
REGION_COL = 2
DATA_COL = 5

GEOJSON_FILE = '../resources/countries.geojson'

# initialize the mapping from date strings to indices,
# starting February 15th, 2020 until May 25th, 2020

date_to_index = {}
dates = []
out_data = []

months = [2, 3, 4, 5]
num_days = [29, 31, 30, 25]

for month_index in range(len(months)):
    month = months[month_index]
    for day in range(num_days[month_index]):
        if month == 2 and day < 14:
            continue
        date = '2020-%02d-%02d' % (month, day+1)
        dates.append(date)
        date_to_index[date] = len(out_data)
        out_data.append({})


# get a list of countries from the auxiliary geojson file
countries = []
with open(GEOJSON_FILE) as geojson_file:
    geojson = json.load(geojson_file)
    for country_json in geojson['features']:
        country = country_json['properties']['name']
        countries.append(country)
countries.sort()

# set up a hand-defined auxiliary mapping to map country names in the
# google file to country names in the geojson file
country_aux_map = {
    'Czechia' : 'Czech Republic',
    'Côte d\'Ivoire' : 'Ivory Coast',
    'Guinea-Bissau' : 'Guinea Bissau',
    'Myanmar (Burma)' : 'Myanmar',
    'North Macedonia' : 'Macedonia',
    'Serbia' : 'Republic of Serbia',
    'Tanzania' : 'United Republic of Tanzania',
    'United States' : 'United States of America',
}

# read the actual data
countries_not_found = set()
with open('Global_Mobility_Report.csv', newline='') as csvfile:
    reader = csv.reader(csvfile, delimiter=',', quotechar='\"')
    idx = -1
    for row in reader:
        if idx < 0:
            idx += 1
            continue
        # if this is regional data, omit it
        if len(row[REGION_COL]) > 0:
            continue
        date     = row[DATE_COL]
        i        = date_to_index[date]
        country  = row[COUNTRY_COL]
        if country in country_aux_map:
            country = country_aux_map[country]
        if country not in countries:
            countries_not_found.add(country)
            continue
        activity = 0
        for j in range(DATA_COL, len(row)):
            if row[j] == '':
                continue
            activity += int(row[j])
        out_data[i][country] = activity

if len(countries_not_found) > 0:
    print('The following countries were not found in the auxiliary geojson file:')
    for entry in sorted(countries_not_found):
        print(entry)

# write an output CSV
with open('mobility_data.csv', 'w', newline='') as csvfile:
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
