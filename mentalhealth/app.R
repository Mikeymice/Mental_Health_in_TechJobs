#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)


library(shinydashboard)
library(tidyverse)
library(leaflet)
library(leaflet.minicharts)
library(maps)
library(mapview)
mapStates = map("world", fill = TRUE, plot = FALSE)
#library(DT)



data <- read.csv("data/clean_data.csv")
geo_location <- read.csv("data/countries.csv")

print(head(geo_location))


mylist <- c(
  "Have sought treamtent for mental condition?" = "treatment",
  "Do your employer provide mental health benefits?" = "benefits",
  "Possible consequence if discuss a mental health issue with employer?" = "mental_health_consequence",
  "Would you bring up a physical health issue with a potential employer in an interview?" = "phys_health_interview",
  "Do you feel that your employer takes mental health as seriously as physical health?" = "mental_vs_physical",
  "Have you heard of or observed negative consequence for coworkers with metnal health condition at workplace?" = "obs_consequence"
)


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



ui <- dashboardPage(
  dashboardHeader(title="Mental Health Perception", titleWidth= 300 ),
  dashboardSidebar(
                # Columns selector

                
                
                uiOutput("columns"),
                uiOutput("singleColumn"),

                # Location selector
                selectInput("country", "Country",
                            choices = countryList, multiple = TRUE
                            ),
                p(" Select None will show all"),
                br(),
                uiOutput("state"),

                # age selector
                sliderInput("ages",
                            "Age Range:",
                            min = 1,
                            max = 99,
                            value = c(20,60)),

                # Genders filters
                # will need to modify based on the cleaned data
                checkboxGroupInput("genders", "Gender",
                                   choices = list("Male" = "Male",
                                                  "Trans Male" = "Trans Female",
                                                  "Female" = "Female",
                                                  "Trans Female" = "Trans Female"),
                                   selected = c("Male", "Female", "Trans Male", "Trans Female")
                                  ),
                   width=300),
  dashboardBody(
    tabsetPanel(id="tabs", type = "tabs",
                tabPanel("Country Map", 
                         leafletOutput("map", height= "800px"), 
                         hr()),
                tabPanel("Plot", 
                         plotOutput("plot", 
                                    height= "700px")),
                tabPanel("Data Explorer", 
                         br(),
                         dataTableOutput("table")))
  )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  

  
  # Get the reactive for the data after filter   
  data_filtered <- reactive(data %>%
                               # filter here 
                               filter(Country %in% input$country | is.null(input$country )) %>% # filter country
                               # filter state
                               # keep country that is not United States OR Country is United state then filter State, Show all States if no State selected
                               filter(Country != "United States" | (Country == "United States" & (state %in% input$state | is.null(input$state))) ) %>%
                               # filter age
                               filter(between(Age, input$ages[1],input$ages[2])) %>%
                               # filter gender 
                               filter(Gender %in% input$genders)
                           )
  # get the data from the filtered and only select the columns that user select
  data_selected <- reactive(
    data_filtered() %>%
      select(input$columns) # need to append the filters values such as gender and age
  )
  
  # map use different filter because we are not filtering countries
  map_data_filtered <- reactive(
    data %>%
      filter(between(Age, input$ages[1],input$ages[2])) %>%
      # filter gender 
      filter(Gender %in% input$genders) %>%
      select(Country, input$singleColumn)
  )

    
    
    # group the data for chart later 
    data_chart_input <- reactive(
       # data_selected() %>%
      data_filtered() %>%
            gather(key = "question", value = "answer", one_of(input$columns))
    )
    
    # Need reactive for graph data input HERE
    
    chart_input <- reactive(
        # use different color and theme 
        data_chart_input() %>%
            ggplot(aes(x = answer, fill = Country)) +
            geom_bar() +
            facet_wrap( question ~ Country,ncol =2,  scales="free") +
            theme(axis.text.x = element_text(angle = 45, hjust = 1), 
                  panel.spacing.x=unit(4.0, "lines"))
                                
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
      data_selected()
      #data_chart_input()
    )
    
    # Barchart
    output$plot <- renderPlot({
     
      if(length(input$columns) !=  0)
        chart_input()
    })
    
    # Map
    output$map <- renderLeaflet({
        # BEWARE, need to check if the all the countries are in the table and has proper geolocation
        data <- map_data_filtered()
        
        values <- unique(data[, input$singleColumn])
        
        spread_data <-data %>%
          group_by(Country, value = data[1:nrow(data), input$singleColumn]) %>%
          summarise(n = n())
         # complete(Country, fill = list(value = 0)) %>%
        
       
        spread_data <- spread_data %>%
          spread(value, n ) %>%
          inner_join(geo_location, by =c("Country" = "name")) %>%
          select(-c("X", "X.1","X.2","country"))
        
        cols <- colnames(spread_data)
        cols <- cols[!( cols%in% c("Country", "latitude", "longitude"))]
        print(cols)
        
        spread_data[is.na(spread_data)] <- 0
        
        spread_data$total <- rowSums(spread_data[,cols], na.rm=TRUE)
        
        print(head(spread_data))
        
        leaflet(data = spread_data, options = leafletOptions(minZoom = 2, maxZoom = 5)) %>%
          addTiles() %>%
          addMinicharts(
            spread_data$longitude, spread_data$latitude,
            type = "pie",
            chartdata = spread_data[, cols], 
            transitionTime = 0, 
            width = 90* sqrt(spread_data$total) / sqrt(max(spread_data$total)), 
            labelText = spread_data$Country, 
            #showLabels = TRUE,
            popup = popupArgs(showTitle = TRUE, showValues = TRUE),
            opacity = 0.7
          ) %>%
          #addCircleMarkers(label=~Country, opacity = 0.0, radius= 10.0001)%>%
          setView(-71.0382679, 42.3489054, zoom = 3)

        
    })
    
    observe({
      print(input$tabs)
    })
    
    # only show column question with multiple select if we are NOT on the map tab
    output$columns <- renderUI(
      if(input$tabs != "Country Map" )
      {
        selectizeInput("columns", "Survey Questions",
                       choices= mylist,
                       multiple = TRUE, # was True 
                       #selected = c("Gender", "Country","Age"), # can remove later
                       options = list(maxItems = 4)
        )
      }

    )
    
    # only show single column if on country map
    output$singleColumn <- renderUI(
      
      if(input$tabs == "Country Map")
      {
        selectizeInput("singleColumn", "Survey Question",
                       choices= mylist,
                       multiple = FALSE, # was True 
        )
      }
    )
    
    
}

# Run the application 
shinyApp(ui = ui, server = server)
