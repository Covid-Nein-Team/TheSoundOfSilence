# The Sound Of Silence &mdash; Quiet Planet

<!-- ![GitHub Workflow Status](https://img.shields.io/github/workflow/status/Covid-Nein-Team/TheSoundOfSilence) -->

Our contribution to the Covid-19 spaceapps challenge! 

### Web App

[Current Development WebApp](https://poehlmann.shinyapps.io/thesoundofsilence/)

### Team Page

[Covid Nein Team](https://covid19.spaceappschallenge.org/challenges/covid-challenges/quiet-planet/teams/covid-nein-team/project)


### Data Sources

- **MODIS Terra CorrectedReflectance TrueColor** [earthdata.nasa.gov MODIS](https://wiki.earthdata.nasa.gov/display/GIBS)
- **Country GeoJSON** [from openlayers workshop](https://raw.githubusercontent.com/openlayers/workshop/cb8374b72d45e7616803b8a8631788c5d319fe13/src/en/data/countries.json)
  - _higher resolution_ https://github.com/datasets/geo-countries
- Also refer to the `data` folder

### Screenshots
- ... none yet

#### R package environment

```
# install the production environment (environment.yml)
make env-production
# or install the dev environment (environment.yml + environment-dev.yml)
make env-development
```

#### Run the app locally

```
make run
```

#### Develop

```
make test  # run tests
make dev-create-test  # create a new test
make test-interactive  # allow stepping through failed tests
```
