import csv
import re

# Accumulates all data in a shared CSV data file with the following columns:
# date, country, dataset, value

data_files = ['co_data.csv', 'covid_19_cases.csv', 'evi_data.csv', 'mobility_data.csv', 'no2_data.csv']
measurement_names = ['Carbon Monoxide', 'COVID-19 cases', 'Enhanced Vegetation Index', 'Google Mobility Index', 'Nitrogen Dioxide']


ymd = re.compile('20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]')

out_data = []

for d in range(len(data_files)):
    data_file = data_files[d]
    measurement = measurement_names[d]
    with open(data_file, newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='\"')
        l = 0
        for row in reader:
            if l == 0:
                countries = row[1:]
                l += 1
                continue
            date = "{:d}-{:02d}-{:02d}".format(*map(int, row[0].split('-')))
            if not ymd.match(date):
                print("not matched", date)
            for c in range(len(countries)):
                out_data.append([date, countries[c], measurement, row[c+1]])

# write an output CSV
with open('accumulated_data.csv', 'w', newline='') as csvfile:
    writer = csv.writer(csvfile, delimiter=',', quotechar='\"', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(['date', 'country', 'dataset', 'value'])
    for row in out_data:
        writer.writerow(row)
