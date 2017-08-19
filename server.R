library(RColorBrewer)
library(dplyr)
library(ggplot2)
#require(data.table)

#Load dataset from US NCEI's Significant Earthquake Database
eqdata <- read.csv(file="results.tsv", sep="\t", header=TRUE)

#Clean the data
eqdata1 <- eqdata[eqdata$YEAR >= 1800, ]
eqdata1 <- eqdata1[!(is.na(eqdata1$LONGITUDE)), ]
eqdata1 <- eqdata1[!(is.na(eqdata1$LATITUDE)), ]
eqdata1 <- eqdata1[!(is.na(eqdata1$EQ_PRIMARY)), ]
eqdata1[(is.na(eqdata1$DEATHS)), "DEATHS"] <- 0
eqdata1[(is.na(eqdata1$DAMAGE_MILLIONS_DOLLARS)), "DAMAGE_MILLIONS_DOLLARS"] <- 0
eqdata1[(is.na(eqdata1$HOUSES_DESTROYED)), "HOUSES_DESTROYED"] <- 0


shinyServer(function(input, output) {
    
    #filter earthquake based on UI inputs
    getEQ <- function() {
        startDate <- input$year[1]
        endDate <- input$year[2]
        minMag <- input$magnitude[1]
        maxMag <- input$magnitude[2]
        
        
        if (input$Region==0) {
            quakedata <- eqdata1[(eqdata1$YEAR >= startDate &
                                eqdata1$YEAR <= endDate) & 
                                (eqdata1$EQ_PRIMARY >= minMag &
                                eqdata1$EQ_PRIMARY <= maxMag) &
                               !(is.na(eqdata1[input$color])), ]
        } else {
            quakedata <- eqdata1[(eqdata1$YEAR >= startDate &
                                eqdata1$YEAR <= endDate) & 
                                (eqdata1$EQ_PRIMARY >= minMag &
                                eqdata1$EQ_PRIMARY <= maxMag) &
                               eqdata1$REGION_CODE == input$Region &
                                !(is.na(eqdata1[input$color])), ]                                   
        }
        return(quakedata)
    }
    

    #leaflet quake map
    qm <- function() {
        quake.get <- getEQ()

        colorBy <- input$color
        if (colorBy == "FLAG_TSUNAMI") {
            colorData <- ifelse(quake.get$FLAG_TSUNAMI != "Tsu", "NONE", "TSUNAMI")
            pal <- colorFactor(c("#0000FF", "#FF0000"), as.factor(colorData))
        } else if (colorBy == "DEATHS") {
            bins <- c(0, 1, 10, 100, 1000, 100000, Inf)
            colorData <- quake.get[[colorBy]]
            pal <- colorBin("magma", domain = quake.get$DEATHS, bins=bins)
            
        } else {
            colorData <- quake.get[[colorBy]]
            pal <- colorBin("magma", colorData, 7, pretty = FALSE)
        }
        
        # create html for popup
        pop <- paste("<b>Mag:</b>", as.character(quake.get$EQ_PRIMARY), "<br>",
                    "<b>Depth:</b>", as.character(quake.get$FOCAL_DEPTH), "km<br>",
                    "<b>Time:</b>", as.character.POSIXt(quake.get$YEAR),
                    "<br>","<b>Fatalities:</b>", quake.get$DEATHS,"<br>",
                    "<b>Country:</b>", quake.get$COUNTRY 
        )
        
        tempmap<-leaflet(data=quake.get) %>% 
            addTiles(urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
                     attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>') %>%
            addCircleMarkers(~LONGITUDE, ~LATITUDE, 
                             popup = pop, stroke=FALSE, 
                             fillColor = ~pal(colorData), 
                             weight = 2, fillOpacity = 0.7, 
                             radius= ~EQ_PRIMARY) %>%
            addLegend("bottomleft", pal=pal, 
                      values=colorData, 
                      title=colorBy,
                      layerId="colorLegend") %>%
            setView(lng = 0, lat = 0, zoom = 1)
    }

    
    # render the map
    output$map <- renderLeaflet(qm())
    
    #filter data based on active map displayed
    eqInBounds <- reactive({
        quake.get <- getEQ()
        if (is.null(input$map_bounds))
            return(eqdata1[FALSE,])
        bounds <- input$map_bounds
        latRng <- range(bounds$north, bounds$south)
        lngRng <- range(bounds$east, bounds$west)
        
        subset(quake.get, LATITUDE >= latRng[1] & LATITUDE <= latRng[2] &
                   LONGITUDE >= lngRng[1] & LONGITUDE <= lngRng[2])

    })

    #create histogram of magnitude based on map actively displayed.    
    magBreaks <- hist(plot = FALSE, eqdata1$EQ_PRIMARY, breaks = 20)$breaks
    output$histMagnitude <- renderPlot({
        if (nrow(eqInBounds()) == 0)
            return(NULL)
        
        hist(eqInBounds()$EQ_PRIMARY,
             #breaks = magBreaks,
             main = "Magnitude",
             col = brewer.pal(20, "Reds"),
             xlab = ""
             )
        
    })

    # create histogram of earthquake occurence over the years 
    # and based on map actively displayed.        
    output$histIntensity <- renderPlot({
        if (nrow(eqInBounds()) == 0)
            return(NULL)
        
        hist(eqInBounds()$YEAR,
             main = "Historgram of Earthquake Count",
             col = brewer.pal(20, "Reds"),
             xlab = "")

        
    })
    
})
