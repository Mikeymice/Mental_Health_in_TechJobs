library(tidyverse)
library(ggmap)

data <- read.csv("data/survey.csv")

countries <- unique(data$Country)

countries_df <- data.frame(country = countries)
countries_df %>% mutate_if(is.factor, as.character) -> countries_df
locations_df <- mutate_geocode(countries_df, country, source = "google")

geocode("Canada", source='google')

str(countries_df$country)
