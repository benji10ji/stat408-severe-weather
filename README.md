# Is U.S. Severe Weather Becoming More Volatile?

**Benjamin Hobbs** | STAT 408, Spring 2026

Dashboard: https://z35ff9-benjamin-hobbs.shinyapps.io/stat408-severe-weather/

## About

My goal is to investigate whether severe weather in the US appears to be becoming more volatile over time. By volatile, I mean not just more frequent on average, but more variable from year to year and harder to predict. This project uses the NOAA Storm Events database to explore four severe convective weather event types from 2016 to 2024: Tornado, Hail, Thunderstorm Wind, and Flash Flood.

This work is part of a larger research project where I plan to use machine learning and operations research for severe weather forecasting.

## Data

The NOAA Storm Events database contains records of significant weather events across the United States going back to 1950. Each row represents a single event, with fields for event type, start date and time, state, location, injuries, deaths, and property damage. I focus on events in the contiguous United States. The raw data is downloaded directly from NOAA and cached locally in `data/raw/`.

## Dashboard Pages

- **About**: Overview of the project and dataset
- **Event Trends**: Annual event counts and top states by event type, with interactive filters
- **Variability**: Monthly distributions by year and year-to-year variability using the coefficient of variation
- **Trend Analysis**: Bayesian Poisson GLM results, including posterior distributions and credible intervals for the annual trend in each event type
- **Summary**: Key findings and links to additional resources

## How to Run

The dashboard is built with Quarto and R Shiny. Open `stat408_final.qmd` in RStudio and click Run Document, or render it with `quarto serve stat408_final.qmd`. Required R packages: `tidyverse`, `lubridate`, `rvest`, `shiny`, `rstanarm`.

On the first run, the data will be downloaded from NOAA and the Stan models will be fit. Both are cached to `data/raw/` so subsequent runs load instantly.
