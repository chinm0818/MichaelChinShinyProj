#
# Shiny app for NYC_oil project (serverside)
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(dplyr)
library(ggplot2)
library(rgdal)
library(googleVis)
library(leaflet)


# Establishing data points and map spatial data

counties = readOGR("nycbb.shp", layer = "nycbb") #nyc boroughs map
district = readOGR("nycc.shp", layer = "nycc")#nyc council district map
oil1 = read.csv('oil_boilers.csv')#alldata
oil2 = oil1 %>%
  filter(., !is.na(Latitude))
dummy = read.csv('dummy.csv')#df of zero values
# nyc_base = ggplot() + geom_polygon(data = counties, aes(x=long, y=lat, group = group)) 
district2 <- spTransform(district, CRS("+proj=longlat +datum=WGS84")) #transform coodtype to Lat Lng

shinyServer(function(input, output) {
  
#let's try to set up our reactive elements:
  
  
  gas_select = reactive({
    switch (input$gas,
            "Con Edison" = "Con Edison",
            "National Grid" = "National Grid",
            "All" = c("Con Edison", "National Grid"))#END Switch
  })#END reactive
  
  boro_select = reactive({
    switch(input$boro,
           "All" = c("Bronx", "Brooklyn", "Manhattan", "Queens", "Staten Island"),
           "Manhattan" = "Manhattan",
           "Bronx" = "Bronx",
           "Brooklyn" = "Brooklyn",
           "Queens" = "Queens",
           "Staten Island" = "Staten Island")
  })
  
  map_select = reactive({
    subset(counties, boro_name %in% boro_select())
  })
  
  map_location = reactive({
    switch(input$boro,
           "All" = c(40.69, -73.8, 11),
           "Manhattan" = c(40.7831, -73.9712, 12),
           "Bronx" = c(40.8448, -73.8648, 12),
           "Brooklyn" = c(40.6782, -73.9442, 12),
           "Queens" = c(40.7, -73.7949, 12),
           "Staten Island" = c(40.5795, -74.1502, 12))
  })

  district_select = reactive({
    switch(input$boro,
           "All" = c(1:51),
           "Manhattan" = c(1:10),
           "Bronx" = c(11:18),
           "Brooklyn" = c(33:48),
           "Queens" = c(19:32),
           "Staten Island" = c(49:51))
  })

    
  filtered_oil2 = reactive({
    oil2 %>%
      filter(., Borough %in% boro_select()) %>%
      filter(., Retirement >= input$year[1] & Retirement <= input$year[2]) %>%
      filter(., Natural.Gas.Utility..Con.Edison.or.National.Grid %in% gas_select())
    
  })
  
  filtered_oil1 = reactive({
    oil1 %>%
      filter(., Borough %in% boro_select()) %>%
      filter(., Retirement >= input$year[1] & Retirement <= input$year[2]) %>%
      filter(., Natural.Gas.Utility..Con.Edison.or.National.Grid %in% gas_select())
    
  })
  
  consumption = reactive ({
    filtered_oil1() %>%
    group_by(., Borough) %>%
    summarize(., Fuel.Consumption = sum(Average.Consumption), Gas.Sales = sum(Dollars.Gas)) %>%
    mutate(., Fuel.Mils = Fuel.Consumption/1000000) 
    
  })
  
  consumption2 = reactive ({
    filtered_oil1() %>%
      group_by(., Council.District) %>%
      summarize(., Fuel.Consumption = sum(Average.Consumption), Gas.Sales = sum(Dollars.Gas)) %>%
      mutate(., Fuel.Thou = Fuel.Consumption/1000) 
    
  })
  
 # leaflet map with geo and data layers 
  output$map <- renderLeaflet({
    
    leaflet() %>%
      addTiles(urlTemplate = 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_nolabels/{z}/{x}/{y}.png') %>%
      setView(40.69, -73.8, 11) %>%
      #addCircles(color = 'red') %>%
      addLayersControl(
        baseGroups = c('boros', 'districts', 'points'),
        options = layersControlOptions(collapsed = FALSE)
      )#END layers control
    
  })#END render leaflet(map)
  
  # putting in leaflet proxy to control map (faster?)
  
  observe({
    req(filtered_oil2()) #req func to require non empty df
    df2 = sp::merge(counties, consumption(), by.x='boro_name', by.y='Borough')
    df3 = sp::merge(district2, consumption2(), by.x='CounDist', by.y='Council.District')

    
    bins = c(0,4,8,12,16,Inf)
    bins2 = c(0,250,500,1000,1500,Inf)
    pal = colorBin('YlOrRd', domain = consumption()$Fuel.Mils, bins = bins)
    dpal = colorBin('YlOrRd', domain = consumption2()$Fuel.Thou, bins = bins2)
    Bpal = colorFactor(topo.colors(23), oil1$Building.Type)
    
    leafletProxy('map', data = filtered_oil2()) %>%
      clearShapes() %>%
      addPolygons(data = df2[df2$boro_name %in% boro_select(),],
                  fillColor = ~pal(Fuel.Mils),
                  weight = 2,
                  opacity = 0.7,
                  fillOpacity = 0.5,
                  color = 'gray',
                  highlight = highlightOptions(
                    weight = 5,
                    color = 'white',
                    dashArray = '',
                    fillOpacity = 0.7,
                    bringToFront = TRUE),
                  label = ~sprintf(
                    "<strong>%s</strong><br/>%g MMBTU of fuel",
                    boro_name, Fuel.Mils
                  ) %>% lapply(htmltools::HTML), #label modified from example. pass data along W/~ to make sure it updates correctly
                  labelOptions = labelOptions(
                    style = list('font-weight' = 'normal', padding = '3px 8px'),
                    textsize = '20px',
                    direction = 'auto'),
                  group = 'boros') %>%
      addCircles(color = ~Bpal(Building.Type), 
                 group = 'points',
                 highlight = highlightOptions(),
                 label = ~sprintf(
                   "%s<br>%s<br/>%0.3g MMBTU of fuel",
                   Facility.Address, Building.Type, Average.Consumption) %>% lapply(htmltools::HTML)) %>%
      addPolygons(data = df3[df3$CounDist %in% district_select(),], 
                  fillColor = ~dpal(Fuel.Thou),
                  weight = 2,
                  opacity = 0.7,
                  fillOpacity = 0.5,
                  color = 'gray',
                  highlight = highlightOptions(
                    weight = 5,
                    color = 'white',
                    dashArray = '',
                    fillOpacity = 0.7,
                    bringToFront = TRUE),
                  label = ~sprintf(
                    "<strong>%s</strong><br/>%g Thousand BTU's of fuel",
                    CounDist, Fuel.Thou
                  ) %>% lapply(htmltools::HTML), #label modified from example. pass data along W/~ to make sure it updates correctly
                  labelOptions = labelOptions(
                    style = list('font-weight' = 'normal', padding = '3px 8px'),
                    textsize = '20px',
                    direction = 'auto'),
                  group = 'districts') %>%
      setView(lat = map_location()[1], lng = map_location()[2], zoom = map_location()[3])
      #addPolylines(data = district2) #leave this out for now. #later add option to toggle districts off and on
  })
  
  # #plotting in ggplot keep incase leaflet gets funky again
  
  # output$map = renderPlot({
  #   ggplot() + 
  #     geom_polygon(data = counties[map_select(),], aes(x=long, y=lat, group = group)) +
  #     geom_polygon(data = district2, aes(x = long, y=lat, group = group, fill = 'blue', alpha = 0.2)) +
  #     geom_point(data = filtered_oil2(), aes(x = Longitude, y = Latitude, color = 'red'))
  # })
  
 
    
    # output$count_data =  renderGvis({
    #   
    #   if(nrow(filtered_oil1()) > 0){
    #   borough = filtered_oil1() %>%
    #       group_by(., Borough) %>%
    #       summarize(., cnt = n())%>% #sum of anything just to get a zero val
    #       as.data.frame
    #   } else {
    #   borough = dummy %>%
    #       group_by(., Borough) %>%
    #       summarize(., cnt = sum(City.Council.District)) %>%
    #       as.data.frame
    #   }#END Conditional
    #   
    #   gvisColumnChart(borough, options = list(width = 400, height=300)) 
    #   })#END Googlevis chart render
    

  output$count_data = renderGvis({
    
    # ggplot(consumption, aes(x = Borough, y = Fuel.Consumption)) + geom_bar(stat = 'identity') +
    #   scale_x_continuous("Borough", breaks = 1:5, labels=c("Mon","Tues","Wed","Th","Fri"))
    
    gvisTable(consumption())
           
  })#END  chart render
  

  output$take_away = renderText({
    
    paste("Between the years", input$year[1],"and", input$year[2],"$", consumption()[dim(consumption())[1],dim(consumption())[2]], "of Natural gas can be sold")
  })#END  chart render
  
  
  output$Btype = renderGvis({
    
    buildingT = filtered_oil1()%>%
      group_by(., Building.Type)%>%
      summarise(., BuildingType = n())
    
    gvisPieChart(buildingT)
  })#END Gvisrender
  
  output$time = renderGvis({
    time = filtered_oil1() %>%
      group_by(., Borough, Retirement) %>%
      summarise(., Fuel.Consumption = sum(Average.Consumption))
    
    gvisLineChart(time)
  })
  
})#END Shiny server


# price of a MMbtu of gas was about 3 dollars in july 2017.* https://www.eia.gov/naturalgas/weekly/

