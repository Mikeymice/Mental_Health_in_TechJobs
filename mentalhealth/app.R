#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)


# test dataset 

data(mtcars)


# read the data

# data clean up 

# define the columns of interests

# extract the columns name into choice list for the filter
choices = data.frame(
    var = names(mtcars),
    num = 1:length(names(mtcars))
)
# List of choices for selectInput
mylist <- as.list(choices$num)
# Name it
names(mylist) <- choices$var


# extract country list choices

# extract state values for choices 


# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Mental Health Preception"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            
            # Columns selector 
            selectInput("columns", "Columns", choices = mylist, multiple = TRUE,
                        selectize = TRUE, width = NULL, size = NULL),
            
            # Location selector
            selectInput("select", "Country", 
                        choices = list("Choice 1" = 1, "Choice 2" = 2, "Choice 3" = 3), 
                        selected = 1),
            selectInput("select", "State (US only)", 
                        choices = list("Choice 1" = 1, "Choice 2" = 2, "Choice 3" = 3), 
                        selected = 1),
            
            # age selector
            sliderInput("ages",
                        "Age Range:",
                        min = 1,
                        max = 99,
                        value = c(20,60)),
            
            # Genders filters
            checkboxGroupInput("genders", "Gender", 
                               choices = list("Male" = 1, "Trans Male" = 2, "Female" = 3, "Trans Female" = 4),
                              )
        ),

        # Show a plot of the generated distribution
        mainPanel(
          # plotOutput("distPlot")
            
            tabsetPanel(type = "tabs",
                        tabPanel("Table", tableOutput("table")),
                        tabPanel("Plot", plotOutput("plot")),
                        tabPanel("Map"), plotOutput("map"))
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {

   
}

# Run the application 
shinyApp(ui = ui, server = server)
