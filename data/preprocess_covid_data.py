import csv

# load data from CSV as provided by the European Union under
# https://data.europa.eu/euodp/de/data/dataset/covid-19-coronavirus-data
# The data format is, for each column:
# 
# date, day, month, year, cases, deaths, countriesAndTerritories, geoId, countryterritoryCode, popData2018, continentExp
#
# We transform this into a table with dates on the y axis, countries on the
# x axis, and normalized cases in the range [0, 1] in each cell.

YEAR_COL = 3
MONTH_COL = 2
DAY_COL = 1
CASES_COL = 4
COUNTRY_COL = 6

# initialize the mapping from date strings to indices,
# starting december 1st, 2019 until May 30th, 2020

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

countries = set()

with open('covid_19_cases_raw.csv', newline='') as csvfile:
    reader = csv.reader(csvfile, delimiter=',', quotechar='\"')
    idx = -1
    for row in reader:
        if idx < 0:
            idx += 1
            continue
        date = '%s-%s-%s' % (row[YEAR_COL], row[MONTH_COL], row[DAY_COL])
        i = date_to_index[date]
        country = row[COUNTRY_COL]
        cases   = row[CASES_COL]
        countries.add(country)
        out_data[i][country] = cases

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
