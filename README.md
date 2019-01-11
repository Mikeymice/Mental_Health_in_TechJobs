# Mental_Health_in_TechJobs
Mental Health survey responses from people working in the tech field. Visualizations and shiny app to explore the data.

## Section 1: Overview

## Section 2: Description of the data

Taken from [Kaggle](https://www.kaggle.com/osmi/mental-health-in-tech-survey)

## Section 3: Usage and scenario tasks

## Section 4: Description of app
The app has a landing page that shows various visualizations of the data according to the filters and graph type selected. The filters consist of List Box for the feature cloumns of the interest such as SO and SO. There are Dropdown lists for Countries and States (US only). Users can also filter the gender by selecting the Checkbox list. 

The data will be displayed as either Datatable, Barchart or Map. Users can select the graph type by clicking on the corresponding tab. Hovering cursor on each bar will display more values as tooltips. Figure 1 shows that Barchart with description of the data below. 
![Alt](img/markup_bar.png)
<center><sup>Figure 1</sup></center>

The Datable tab (as shown in Figure 2) will allow user to examine raw data and search for certain value such as Coutry or State.
![Alt](img/markup_datatable.png)
<center><sup>Figure 2</sup></center>

The Map tab will showcase how each each variable distributed in each country. Each pie chart should display the proportion. Hovering cursor on each location should display more values such as total number as tooltips

![Alt](img/markup_map.png)
<center><sup>Figure 3</sup></center>


When users select multiple columns, the app will display multiple graphs in the single tab as shown below
![Alt](img/markup_multi.png)
<center><sup>Figure 4</sup></center>




- Proposal: We will create a shiny app for users to explore the question: How do mental health perceptions differ accross genders and countries/states?
