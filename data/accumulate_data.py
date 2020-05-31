import csv
import re

# Accumulates all data in a shared CSV data file with the following columns:
# date, country, dataset, value

data_files = ['co_data.csv', 'covid_19_cases.csv', 'evi_data.csv', 'mobility_data.csv', 'no2_data.csv']
measurement_names = ['Carbon Monoxide', 'COVID-19 cases', 'Enhanced Vegetation Index', 'Google Mobility Index', 'Nitrogen Dioxide']

# set up the desired date range, which should be uniform across all data types

dates = []
for day in range(31):
    date = '2019-12-%02d' % (day+1)
    dates.append(date)

num_days = [31, 29, 31, 30, 31]

for month in range(len(num_days)):
    for day in range(num_days[month]):
        date = '2020-%02d-%02d' % (month + 1, day+1)
        dates.append(date)

ymd = re.compile('20[0-9][0-9]-[0-9][0-9]-[0-9][0-9]')

out_data = []

for d in range(len(data_files)):
    data_file = data_files[d]
    measurement = measurement_names[d]
    with open(data_file, newline='') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='\"')
        first_row = True
        t = 0
        for row in reader:
            if first_row:
                countries = row[1:]
                first_row = False
                continue
            date = "{:d}-{:02d}-{:02d}".format(*map(int, row[0].split('-')))
            if not ymd.match(date):
                raise ValueError('invalid date: %s' % date)
            # if the date is earlier than the preferred date range, ignore it
            if date < dates[0]:
                continue
            # fill in nan dates between the last date and the current date
            while date != dates[t]:
                for c in range(len(countries)):
                    out_data.append([date, countries[c], measurement, float('nan')])
                t += 1
                if t >= len(dates):
                    raise ValueError('Date not found: %s' % date)
            # insert the actual data row
            for c in range(len(countries)):
                out_data.append([date, countries[c], measurement, row[c+1]])
            t += 1
        # insert nan rows for the remaining dates
        while t < len(dates):
            for c in range(len(countries)):
                out_data.append([date, countries[c], measurement, float('nan')])
            t += 1

# write an output CSV
with open('accumulated_data.csv', 'w', newline='') as csvfile:
    writer = csv.writer(csvfile, delimiter=',', quotechar='\"', quoting=csv.QUOTE_MINIMAL)
    writer.writerow(['date', 'country', 'dataset', 'value'])
    for row in out_data:
        writer.writerow(row)
