#Load Library
library(leaflet)
library(shiny)


Region <- list("All" = 0,
               "Central, Western and S. Africa" = 10,
               "Northern Africa" = 15,
               "Antarctica" = 20,
               "East Asia" = 30,
               "Central Asia and Caucasus" = 40,
               "Kamchatka and Kuril Islands" = 50,
               "S. and SE. Asia and Indian Ocean" = 60,
               "Atlantic Ocean" = 70,
               #"Bearing Sea" = 80,
               "Caribbean" = 90,
               "Central America" = 100,
               "Eastern Europe" = 110,
               "Northern and Western Europe" = 120,
               "Southern Europe" = 130,
               "Middle East" = 140,
               "North America and Hawaii" = 150,
               "South America" = 160,
               "Central and South Pacific" = 170)

color <- list("Tsunami" = "FLAG_TSUNAMI",
              "Year" = "YEAR",
              "Focal Depth" = "FOCAL_DEPTH",
              "Magnitude" = "EQ_PRIMARY",
              "Intensity"= "INTENSITY",
              "Deaths" = "DEATHS",
              "Damage(M$)" = "DAMAGE_MILLIONS_DOLLARS",
              "Houses Destroyed" = "HOUSES_DESTROYED")





# Define UI for application that draws a histogram
shinyUI(fluidPage(
    
    # Application title
    titlePanel("The Significant Earthquake Database"),
    
    # Sidebar with a slider input for number of bins 
    sidebarLayout(sidebarPanel(width = 3,
            sliderInput("year", "Year:", min = 1800, max = 2017, value = c(1950, 2017)),
            sliderInput("magnitude", "Magnitude:", min = 1, max = 10, value = c(1,10)),
            selectInput("Region", "Select a Region:", choices = Region),
            selectInput("color", "Color of Circle:", choices = color),
            p("Source: National Geophysical Data Center / World Data Service (NGDC/WDS): Significant Earthquake Database")
                       
        ),
        
        
        # Show a plot of the generated distribution
        mainPanel(
            leafletOutput("map"),
            plotOutput("histMagnitude", height = 200),
            plotOutput("histIntensity", height = 250)
            
        )
    )
))
