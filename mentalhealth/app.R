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

library(maps)
mapStates = map("state", fill = TRUE, plot = FALSE)
#library(DT)

# test dataset 
#data <- data(mtcars)

data <- read.csv("data/survey.csv")

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
            # selectInput("columns", "Columns", choices = mylist, multiple = TRUE,
            #             selectize = TRUE, width = NULL, size = NULL),
            
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
                        tabPanel("Table", dataTableOutput("table")),
                        tabPanel("Plot", plotOutput("plot")),
                        tabPanel("Map", leafletOutput("map")))
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
                               filter(Country != "United States" | (Country == "United States" & (state %in% input$state | is.null(input$state))) ) %>%
                               # filter age
                               filter(between(Age, input$ages[1],input$ages[2])) %>%
                               # filter gender 
                               filter(Gender %in% input$genders) %>%
                               select(input$columns) # need to append the filters values such as gender and age
                           )
    
    # Need reactive for graph data input HERE
    # need to group/gather the columns to one column for question and one for answer 
    
    # state output
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
    )
    
    
    
    # Barchart
    output$plot <- renderPlot({
        data_input() %>%
            ggplot(aes(input$columns)) + # need to change it to one single columns 
            geom_bar()
        # add faccet here for multiipoe columns 
    })
    
    # Map
    output$map <- renderLeaflet({
        leaflet(mapStates) %>%
            addTiles() %>%  # Add default OpenStreetMap map tiles
            addMarkers(lng=174.768, lat=-36.852, popup="The birthplace of R")
        
    })
    
}

# Run the application 
shinyApp(ui = ui, server = server)
