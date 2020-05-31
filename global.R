# thesoundofsilence global
# ========================
# Created by: Covid Nein Team

# imports ----
library(tidyverse)
library(here)
library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(shinyWidgets)
library(shinyjqui)
library(vapoRwave)

# App Settings:
APP_NAME <- "The Sound Of Silence"
REPO_URL <- "https://github.com/Covid-Nein-Team/TheSoundOfSilence"

# Google Analytics ----
source("modules/google_analytics.R", local = FALSE)
GA_TOKEN <- google_analytics_read_token_file(here("GOOGLE_ANALYTICS.token"))

# Add readme resources
shiny::addResourcePath('mapdata', './resources')
