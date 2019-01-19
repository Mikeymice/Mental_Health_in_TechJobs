library(tidyverse)
library(ggplot2)
library(maps)
library(leaflet)

data <- read.csv("data/survey.csv")

# get columns names
cols <- colnames(data)
cols
cols_selected <- c('family_history', 'treatment', 'work_interfere', 'no_employees')



str(cols_selected)


# to graph from the columns selected
data %>%
  gather(key = "question", value = "answer",one_of(cols_selected)) %>%
  ggplot(aes(x = answer)) +
  geom_bar() +
  facet_wrap( ~ question, ncol=2, scales="free_x") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))



data %>%left_join(geo_location,by = c("Country"="name") )



#ggplot() +  geom_polygon(data=world_map,aes(x=long, y=lat,group=group))
world_map <- map_data("world") %>%
  group_by(region, subregion) %>%
  summarise(long = mean(long), lat = mean(lat))
