#
# Shiny app for NYC_oil project
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shinydashboard)
library(leaflet)

shinyUI(dashboardPage(
  dashboardHeader(title = "My Dashboard"),
  dashboardSidebar(
    sidebarUserPanel("Your Name"),
    sidebarMenu(
      menuItem("Map", tabName = "map", icon = icon("map")),
      menuItem("Data", tabName = "data", icon = icon("database"))),
    selectizeInput("gas",
                   "Gas Provider",
                   choice = c('All',
                   'Con Edison', 'National Grid')),
    selectizeInput("boro",
                   "Select Borough",
                   choice = c('All','Bronx', 'Brooklyn', 'Manhattan', 'Queens', 'Staten Island')),
    sliderInput("year",
                label = h3('Year Range'),
                min = 2018,
                max = 2030,
                value = c(2018, 2020)
                )
    ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "map",
              fluidRow(leafletOutput('map'))),
      tabItem(tabName = "data",
              "to be replaced with datatable"))
  )
  )
  )
