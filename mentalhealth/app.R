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

############## Extract Columns Names as options in the drop down list ############

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


############################  END  ###########################


# Define UI for application that draws a histogram
# ui <- fluidPage(
# 
#     # Application title
#     titlePanel("Mental Health Preception"),
# 
#     # Sidebar with a slider input for number of bins
#     sidebarLayout(
#         sidebarPanel(
# 
#             # Columns selector
# 
#             selectizeInput("columns", "Columns",
#                            choices= mylist,
#                            multiple = TRUE,
#                            selected = c("Gender", "Country","Age"), # can remove later
#                            options = list(maxItems = 12)),
# 
#             hr(),
#             # Location selector
#             selectInput("country", "Country",
#                         choices = countryList, multiple = TRUE
#                         ),
#             p("Select None will show all"),
#             br(),
#             uiOutput("state"),
# 
# 
#             hr(),
# 
#             # age selector
#             sliderInput("ages",
#                         "Age Range:",
#                         min = 1,
#                         max = 99,
#                         value = c(20,60)),
# 
#             # Genders filters
#             # will need to modify based on the cleaned data
#             checkboxGroupInput("genders", "Gender",
#                                choices = list("Male" = "Male",
#                                               "Trans Male" = "Trans Female",
#                                               "Female" = "Female",
#                                               "Trans Female" = "Trans Female"),
#                                selected = c("Male", "Female", "Trans Male", "Trans Female")
#                               )
#         ),
# 
#         # Show a plot of the generated distribution
#         mainPanel(
#           # plotOutput("distPlot")
# 
#             # may need to add stringoutput for description
#             tabsetPanel(type = "tabs",
#                         tabPanel("Map", leafletOutput("map", height= "400px"), hr(), plotOutput("mapplot", height= "700px")),
#                         tabPanel("Plot", plotOutput("plot", height= "700px")),
#                         tabPanel("Data Explorer", br(),dataTableOutput("table")))
#         )
#     )
# )

ui <- dashboardPage(
  dashboardHeader(title="Mental Health Perception", titleWidth= 300 ),
  dashboardSidebar(
                # Columns selector

                selectizeInput("columns", "Columns",
                               choices= mylist,
                               multiple = TRUE, # was True 
                               #selected = c("Gender", "Country","Age"), # can remove later
                               #options = list(maxItems = 12)
                               ),
                selectizeInput("singleColumn", "single Column",
                               choices= mylist,
                               multiple = FALSE, # was True 
                ),

               # hr(),
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
    tabsetPanel(type = "tabs",
                tabPanel("Country Map", 
                         leafletOutput("map", height= "700px"), 
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
  
  
  map_data_filtered <- reactive(
    data %>%
      filter(between(Age, input$ages[1],input$ages[2])) %>%
      # filter gender 
      filter(Gender %in% input$genders) %>%
      select(Country, input$singleColumn)
  )
    # get the data from the filtered and only select the columns that user select
    data_selected <- reactive(
      data_filtered() %>%
      select(input$columns) # need to append the filters values such as gender and age
    )
    
    # return country plot object for show individual country 
    # get_country_plot <- function(long, lat ){
    #   p <-data_filtered() %>%
    #     left_join(geo_location, by=c("Country" = "name")) %>%
    #     filter(longitude == long & latitude == lat) %>%
    #     gather(key = "question", value = "answer", one_of(input$columns)) %>%
    #     ggplot(aes(x = answer)) +
    #     geom_bar(colour= answer) +
    #     facet_wrap( ~ question, ncol=2, scales="free") +
    #     theme(axis.text.x = element_text(angle = 45, hjust = 1))
    #   
    #   if (is.na(p))
    #   {
    #     return(NA) # dont return anything if there is no data from filtered 
    #   }else
    #     return(p)
    #   
    #   
    #   
    # }
    
    
    
    
    # group the data for chart later 
    data_chart_input <- reactive(
        data_selected() %>%
            gather(key = "question", value = "answer", one_of(input$columns))
    )
    
    # Need reactive for graph data input HERE
    
    chart_input <- reactive(
        # use different color and theme 
        data_chart_input() %>%
            ggplot(aes(x = answer, fill = answer)) +
            geom_bar() +
            facet_wrap( ~ question, ncol=2, scales="free") +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
                                
                            )
    # need to group/gather the columns to one column for question and one for answer 
    
    # mainly for drawing markers on the map. 
    # filter the only countries that appears in the filtered data 
    map_input <- reactive(

        geo_location %>%
            inner_join(data_filtered(),by = c("name"="Country") )
       
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
        
        
       # print(values)
        spread_data[is.na(spread_data)] <- 0
        
        
        spread_data$total <- rowSums(spread_data[,cols], na.rm=TRUE)
        
        print(head(spread_data))
        
        leaflet(data = spread_data, options = leafletOptions(minZoom = 3, maxZoom = 5)) %>%
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
          setView(-71.0382679, 42.3489054, zoom = 3)
      
        
        # 
        # if(nrow(map_input())!= 0)
        #   baseMap <- leaflet(data = map_input()) %>%
        #     addTiles() %>%
        #     addMarkers(lat = ~latitude, 
        #                lng=~longitude, 
        #                label = ~name, 
        #                popup = ~name,
        #                popupOptions = popupOptions(closeButton = FALSE)) 
        # 
        # 
        # else
        #   baseMap <- leaflet() %>%
        #     addTiles()
        #     
        # baseMap
        
    })
    
    
    # Mapplot render

    
    output$mapplot <- renderPlot({
        
        p <- input$map_marker_click
        if(is.null(p) || length(input$columns) ==0) # need to check if the current click is in the list
        {
            return() # dont show anything if no mark is clicked
        }
        else
        {
          
          get_country_plot(input$map_marker_click$lng, input$map_marker_click$lat)
          
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
