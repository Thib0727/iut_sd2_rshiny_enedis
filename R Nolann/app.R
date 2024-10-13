# INSTALLATION DES PACKAGES NECESSAIRES
# install.packages('rsconnect')
# library(rsconnect)
# 
# rsconnect::setAccountInfo(name='greentech-r-but2-2024', token='F25C71F0A0415C73AA94CFAAB40F7DB8', secret='AHzEfHpi8AOxpGV8R7LYyRfSijJ5UTgbKNbZtdNN')


# install.packages(c("shiny", "httr", "jsonlite", "RMySQL", "tidygeocoder", "leaflet", "readr", "shinyjs", "shinydashboard", "dplyr", "rgdal", "sp","DT","ggplot2","markdown"))
# CHARGEMENT DES PACKAGES NECESSAIRES
library(markdown)
library(shiny)
library(httr)
library(jsonlite)
library(RMySQL)
library(tidygeocoder)
library(leaflet)
library(readr)
library(shinyjs)
library(shinydashboard)
library(dplyr)
library(DT)
library(sp)
library(ggplot2)

# setwd("./")
# getwd()

# MISE EN COMMUN DES DEUX FICHIERS
source(file= "./main/ui.R",chdir=T)
source(file= "./main/server.R",chdir=T)

# CREATION APP
shinyApp(ui = ui, server = server)
