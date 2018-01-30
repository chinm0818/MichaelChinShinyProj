#
# Shiny app for NYC_oil project
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#



library(leaflet)
library(shinydashboard)



shinyUI(dashboardPage(
  dashboardHeader(title = 'Phasing Out Oil Heat'),
  dashboardSidebar(
    
    #sidebarUserPanel("Selection Panel"),
    sidebarMenu(
      
      menuItem("Map", tabName = "map", icon = icon("map")),
      menuItem("Data", tabName = "data", icon = icon("database")),
      menuItem("About", tabName = "About", icon = icon("info"))
    ), #End sidebar menu
    
    sliderInput('year', 
                label = 'Year Range',
                min = 2018,
                max = 2030,
                value = c(2018, 2020)),
    
    selectInput('gas',
                label = 'Gas Provider',
                choice = c('All', 'Con Edison', 'National Grid')),
    
    selectInput('boro', 
                label = 'Select Borough',
                choice = c('All NYC', 'Bronx', 'Brooklyn', 'Manhattan', 'Queens', 'Staten Island'))
  ), #END DBsidebar
  
  dashboardBody(
    tabItems(
      tabItem(tabName = 'map',
              leafletOutput('map', width = '100%', height = '900'),
              absolutePanel(top = 100, right = 100, width = 600,
                            h2(htmlOutput('take_away'),
                            tags$head(tags$style('#take_away{color: white;'))
                            )
                            )#END absolute panel
      ),#End tabItem(map)
      
      tabItem(tabName = 'data',
              #htmlOutput('count_data'),
              fluidRow(plotOutput('time', width = '800px'), htmlOutput('Btype'))
      ),#End tabItem(data)
      tabItem(tabName = 'About',
              helpText(HTML("<strong>Goal:<strong><br/>
                            Provide user with a convenient breakdown of when oil boilers are scheduled for replacement,<br/>
                            the borough and neighborhood these boilers are situated, and building type boiler is situated in<br/>")),
              helpText("Data sources and extra reading:"),
              
              helpText(a("NYC Boiler Data",
                            href="https://data.cityofnewyork.us/Housing-Development/Oil-Boilers-Detailed-Fuel-Consumption-and-Building/jfzu-yy6n", target = "_blank")),
              helpText(a("NYC Borough & District shapefiles",
                            href="https://www1.nyc.gov/site/planning/data-maps/open-data/districts-download-metadata.page<br/>", target = "_blank")),
              
              
              helpText(a("Cost Among Hurdles Slowing New York City's Plan to Phase Out Dirty Heating Oil",
                              href= "https://www.nytimes.com/2014/04/07/nyregion/cost-among-hurdles-slowing-new-yorks-plan-to-phase-out-dirty-heating-oil.html", target = "_blank")),
              helpText(a("NYC Retrofit Accelerator Program", 
                        href = "https://retrofitaccelerator.cityofnewyork.us/resources/heating-oil-conversions", target = "_blank"))
                   
                         
      )#END Tabitem(about)
    )#End tabItems
  )#END DB body
)#END Dashboard
)#END ShinyUI



## left over code from trying non-dashboard ui

# fluidPage(
#   leafletOutput('map', width = '2000', height = '1000'),
#   absolutePanel(top = 10, left = 10,
#                 sliderInput('year',
#                             label = 'Year Range',
#                             min = 2018,
#                             max = 2030,
#                             value = c(2018, 2020)),
#                 selectInput('gas',
#                             'Gas Provider',
#                             choice = c('All', 'Con Edison', 'National Grid')),
#                 selectInput('boro',
#                             'Select Borogh',
#                             choice = c('All', 'Bronx', 'Brooklyn', 'Manhattan', 'Queens', 'Staten Island'))
#   ),
#   
#   fluidRow(htmlOutput('Btype'), plotOutput('count_data'))
#                
# )#END fluidPage



