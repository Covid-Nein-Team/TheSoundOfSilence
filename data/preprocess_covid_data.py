import csv
import json

# preprocesses CSV data as provided by the European Union under
# https://data.europa.eu/euodp/en/data/dataset/covid-19-coronavirus-data
# The expected data format is, for each row:
# 
# date, day, month, year, cases, deaths, countriesAndTerritories, geoId, countryterritoryCode, popData2018, continentExp
#
# We transform this into a table with dates on the y axis, countries on the
# x axis, and number of cases in each cell.

YEAR_COL = 3
MONTH_COL = 2
DAY_COL = 1
CASES_COL = 4
COUNTRY_COL = 6

GEOJSON_FILE = '../resources/countries.geojson'

# get a list of countries from the auxiliary geojson file
countries = []
with open(GEOJSON_FILE) as geojson_file:
    geojson = json.load(geojson_file)
    for country_json in geojson['features']:
        country = country_json['properties']['name']
        countries.append(country)
countries.sort()

# initialize the mapping from date strings to indices,
# starting december 1st, 2019 until May 31st, 2020

date_to_index = {}
dates = []
out_data = []
for day in range(31):
    date = '2019-12-%d' % (day+1)
    dates.append(date)
    date_to_index[date] = len(out_data)
    out_data.append({})

num_days = [31, 29, 31, 30, 31]

for month in range(len(num_days)):
    for day in range(num_days[month]):
        date = '2020-%d-%d' % (month + 1, day+1)
        dates.append(date)
        date_to_index[date] = len(out_data)
        out_data.append({})

countries_not_found = set()
with open('covid_19_cases_raw.csv', newline='') as csvfile:
    reader = csv.reader(csvfile, delimiter=',', quotechar='\"')
    idx = -1
    for row in reader:
        if idx < 0:
            idx += 1
            continue
        date = '%s-%s-%s' % (row[YEAR_COL], row[MONTH_COL], row[DAY_COL])
        i = date_to_index[date]
        country = row[COUNTRY_COL].replace('_', ' ')
        if country == 'Czechia':
            country = 'Czech Republic'
        if country not in countries:
            countries_not_found.add(country)
            continue
        cases   = row[CASES_COL]
        out_data[i][country] = cases

if len(countries_not_found) > 0:
    print('The following countries were not found in the auxiliary geojson file:')
    for entry in sorted(countries_not_found):
        print(entry)

# sort all countries contained in the data
countries = list(sorted(countries))

# write an output CSV
with open('covid_19_cases.csv', 'w', newline='') as csvfile:
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
