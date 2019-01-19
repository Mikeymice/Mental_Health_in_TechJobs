#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(leaflet)
library(leaflet.minicharts)
library(maps)
mapStates = map("world", fill = TRUE, plot = FALSE)
#library(DT)

# test dataset 
#data <- data(mtcars)

data <- read.csv("data/survey.csv")
geo_location <- read.csv("data/countries.csv")

print(head(geo_location))

# Load dataset HERE!!

# read the data

# data clean up 

# define the columns of interests

# extract the columns name into choice list for the filter
choices = data.frame(
    var = names(data), # need to change it to the values inside the "Question" Column
    num = names(data)
)
# List of choices for selectInput
mylist <- as.list(choices$num)
# Name it
names(mylist) <- choices$var


# extract country list choices
countries<-unique(sort(data$Country))
country_choices = data.frame(
    var = countries, # need to change it to the values inside the "Question" Column
    num = countries
)
# List of choices for selectInput
countryList <- as.list(country_choices$num)
# Name it
names(countryList) <- country_choices$var


# extract state values for choices 
states <- unique(sort(data$state))
state_choices = data.frame(
    var = states,
    num = states
)
# List of choices for selectInput
stateList <- as.list(state_choices$num)
# Name it
names(stateList) <- state_choices$var


# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Mental Health Preception"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            
            # Columns selector 

            selectizeInput("columns", "Columns", 
                           choices= mylist, 
                           multiple = TRUE, 
                           selected = c("Gender", "Country","Age"),
                           options = list(maxItems = 12)),
            
            hr(),
            # Location selector
            selectInput("country", "Country", 
                        choices = countryList, multiple = TRUE 
                        ),
            p("Select None will show all"),
            br(),
            uiOutput("state"),
            
            
            hr(),
            
            # age selector
            sliderInput("ages",
                        "Age Range:",
                        min = 1,
                        max = 99,
                        value = c(20,60)),
            
            # Genders filters
            checkboxGroupInput("genders", "Gender", 
                               choices = list("Male" = "Male", 
                                              "Trans Male" = "Trans Female", 
                                              "Female" = "Female", 
                                              "Trans Female" = "Trans Female"),
                               selected = c("Male", "Female", "Trans Male", "Trans Female")
                              )
        ),

        # Show a plot of the generated distribution
        mainPanel(
          # plotOutput("distPlot")
            
            tabsetPanel(type = "tabs",
                        tabPanel("Map", leafletOutput("map", height= "400px"), hr(), plotOutput("mapplot", height= "700px")),
                        tabPanel("Plot", plotOutput("plot", height= "700px")),
                        
                        tabPanel("Data Explorer", br(),dataTableOutput("table")))
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

   # reactive data here
   
    data_input <- reactive(data %>%
                               # filter here 
                               filter(Country %in% input$country | is.null(input$country )) %>% # filter country
                               # filter state
                               # keep country that is not United States OR Country is United state then filter State, Show all States if no State selected
                               filter(Country != "United States" | (Country == "United States" & (state %in% input$state | is.null(input$state))) ) %>%
                               # filter age
                               filter(between(Age, input$ages[1],input$ages[2])) %>%
                               # filter gender 
                               filter(Gender %in% input$genders) %>%
                               select(input$columns) # need to append the filters values such as gender and age
                          
                           )
    data_chart_input <- reactive(
        data_input() %>%
            gather(key = "question", value = "answer", one_of(input$columns))
    )
    
    # Need reactive for graph data input HERE
    
    chart_input <- reactive(
        # use different color and theme 
        data_chart_input() %>%
            ggplot(aes(x = answer)) +
            geom_bar() +
            facet_wrap( ~ question, ncol=2, scales="free") +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
                                
                            )
    # need to group/gather the columns to one column for question and one for answer 
    
    
    map_input <- reactive(
        # get the country geolocation 
        # Need to debug for loss data
        geo_location %>%
            semi_join(data_input(),by = c("name"="Country") ) # neeed to debug and clean up 
        
       
    )
    
    

    
    
    # state output Only show the state option when USA is selected
    output$state <- renderUI(
        if ("United States" %in% input$country)
        {
            selectInput("state", "State (US only)", 
                        choices = stateList, multiple = TRUE
            )
        }
    )
    
    # Datatable
    
    output$table <- renderDataTable(
      data_input()
       # map_input()
    )
    
    
    
    # Barchart
    output$plot <- renderPlot({
        chart_input()
    })
    
    # Map
    output$map <- renderLeaflet({
        # BEWARE, need to check if the all the countries are in the table and has proper geolocation
        leaflet(data = map_input()) %>%
            addTiles() %>%  # Add default OpenStreetMap map tiles
            #addPolygons(fillColor = topo.colors(10, alpha = NULL), stroke = FALSE) %>%
            addMarkers(  lat = ~latitude, lng=~longitude, label = ~name, popup = ~name)
            
        
        # ALSO need to make sure how to draw the state as well 
        
        
    })
    
    
    # Mapplot render
    
    output$mapplot <- renderPlot({
        
        p <- input$map_marker_click
        if(is.null(p))
        {
            chart_input()
        }
        else
        {
            data_input() %>% 
                left_join(geo_location, by=c("Country" = "name")) %>%
                filter(longitude == input$map_marker_click$lng & latitude == input$map_marker_click$lat) %>%
                gather(key = "question", value = "answer", one_of(input$columns)) %>%
                ggplot(aes(x = answer)) +
                geom_bar() +
                facet_wrap( ~ question, ncol=2, scales="free") +
                theme(axis.text.x = element_text(angle = 45, hjust = 1))   
        }
        
        
    })
    
    # testing marker click 
    observeEvent(input$map_marker_click, { 
        p <- input$map_marker_click  # typo was on this line
        print(p)
    })
    
    #testing for pop up close event. THIS IS NOT WORKING, Trying to use this event to clear the plot under the map
    # May not be implemented yet 
    observeEvent(input$map_popup_click, { 
         # typo was on this line
        print("CLICKED")
    })
    
}

# Run the application 
shinyApp(ui = ui, server = server)
