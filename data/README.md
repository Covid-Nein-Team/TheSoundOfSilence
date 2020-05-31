# Data Sources overview

This folder contains several data sources both in raw format and in a
preprocessed format for sonification. The preprocessed format is a CSV file
with one row per day and one column per country. The days start, at the
earliest, on December 1st, 2019, and end, at the latest, on May 31st, 2020.

In more detail, the following preprocessed data files are contained:

1. `covid_19_cases.csv`: Contains the number of COVID-19 cases per country
    as reported on the respective day. This data is provided by the
    [European Union][1].
2. `mobility_data.csv`: Contains the change in visits to six areas of
    daily life in percent versus baseline. Since six areas are added up,
    the minimum is -600. This data is provided by [Google][2].
3. `co_data.csv`: Contains measurements of carbon monoxide (CO) in the
    troposphere in exa-moles per cubic centimetre (i.e. 10^18) as reported by
    the [MOPITT mission][3] by the Canadian Space Agency. The data is
    pre-processed to an average per country per day, using the geo-location
    data as contained in the `../resources/countries.geojson` file.
4. `no2_data.csv`: Contains measurements of nitrogen dioxide (NO2) in the
    troposphere in molecules per square centimetre as reported by the
    [OMI Mission][4] 

In addition to these files, we also supply the following auxiliary files that
we used to pre-process the data.

* `covid_19_cases_raw.csv` : A copy of the `COVID-19 cases worldwide` file
    as provided by the [European Union][1].
* `Global_Mobility_Report.csv` : The raw data file of the
    [Google COVID-19 Community Mobility Report][2]
* `mopitt_raw_data/load_moppit_data.sh` : A script to load [MOPITT][3]
    measurements from NASA.
* `mopitt_raw_data/mopitt_links.txt` : A file containing the links to
    load [MOPITT][3] data from NASA.
* `omi_raw_data/load_omi_data.sh` : A script to load [OMI][4] measurements
    from NASA.
* `preprocess_covid_data.py` : A Python3 script to transform the
    `covid_19_cases_raw.csv` file into the `covid_19_cases.csv` file.
* `preprocess_google_data.py`: A Python3 script to transform the
    `Global_Mobility_Report.csv` file into the `mobility_data.csv` file.
* `preprocess_mopitt_data.py` : A Python3 script to transform the
    data downloaded via `load_moppit_data.sh` into the `co_data.csv` file.
* `preprocess_omi_data.py` : A Python3 script to transform the
    data downloaded via `load_omi_data.sh` into the `no2_data.csv` file.

[1]:https://data.europa.eu/euodp/en/data/dataset/covid-19-coronavirus-data "Covid 19 data page by the European Union."
[2]:https://www.google.com/covid19/mobility/ "COVID-19 Community Mobility Reports."
[3]:https://www2.acom.ucar.edu/mopitt "MOPITT Mission page."
[4]:https://aura.gsfc.nasa.gov/omi.html "OMI Mission page."
