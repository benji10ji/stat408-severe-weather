library(tidyverse)
library(rstanarm)

# Load the combined event data
severe_events = read_csv(
  file.path("data", "raw", "storm_events_raw_combined.csv"),
  col_types = cols(.default = col_character()),
  show_col_types = FALSE
) |>
  select(BEGIN_DATE_TIME, EVENT_TYPE, STATE,
         BEGIN_LAT, BEGIN_LON, INJURIES_DIRECT, DEATHS_DIRECT) |>
  filter(EVENT_TYPE %in% c("Tornado", "Hail", "Thunderstorm Wind", "Flash Flood")) |>
  mutate(
    begin_dt = lubridate::ymd_hms(BEGIN_DATE_TIME),
    year = lubridate::year(begin_dt),
    BEGIN_LAT = as.numeric(BEGIN_LAT),
    BEGIN_LON = as.numeric(BEGIN_LON)
  ) |>
  filter(!is.na(begin_dt), !is.na(BEGIN_LON), !is.na(BEGIN_LAT),
         between(BEGIN_LON, -125, -66), between(BEGIN_LAT, 24, 50))

event_types_keep = c("Tornado", "Hail", "Thunderstorm Wind", "Flash Flood")

# Count events by year and event type, then center year at 2020 to
# reduce correlation between the intercept and slope posteriors
annual_counts = severe_events |>
  count(year, EVENT_TYPE) |>
  mutate(year_c = year - 2020)

# Fit a separate Bayesian Poisson GLM for each event type
glm_fits = setNames(
  map(event_types_keep, function(et) {
    # Pull only the rows for this event type
    df = filter(annual_counts, EVENT_TYPE == et)
    stan_glm(
      # Model the log event rate as a linear function of year
      n ~ year_c,
      # Poisson family with log link for count data
      family = poisson(link = "log"),
      data = df,
      # Two chains with 1500 post-warmup draws each
      chains = 2, iter = 2000, warmup = 500,
      # Suppress progress messages, fix seed for reproducibility
      refresh = 0, seed = 408
    )
  }),
  event_types_keep
)

# Extract the posterior draws for the year coefficient and build a summary
# table showing the mean, 90% credible interval, and P(trend > 0) per event type
glm_summary = map_dfr(event_types_keep, function(et) {
  # Pull posterior samples for the year coefficient from this fitted model
  samps = as.data.frame(glm_fits[[et]])[["year_c"]]
  tibble(
    `Event Type` = et,
    # Posterior mean of the year coefficient
    `Mean` = round(mean(samps), 3),
    # Lower and upper bounds of the 90% credible interval
    `5th %` = round(quantile(samps, 0.05), 3),
    `95th %` = round(quantile(samps, 0.95), 3),
    # Share of posterior draws above zero
    `P(trend > 0)` = round(mean(samps > 0), 2)
  )
}) |>
  # Combine the two CI bound columns into a single display column
  mutate(`90% CI` = paste0("[", `5th %`, ", ", `95th %`, "]")) |>
  select(`Event Type`, `Mean`, `90% CI`, `P(trend > 0)`)

# Collect all posterior draws into one data frame so they can be overlaid
# in a density plot on the Trend Analysis page
glm_posterior = map_dfr(event_types_keep, function(et) {
  samps = as.data.frame(glm_fits[[et]])[["year_c"]]
  tibble(EVENT_TYPE = et, coef = samps)
})

# Save the summary and posterior draws so the dashboard can load them without Stan
saveRDS(glm_summary, file.path("data", "raw", "glm_summary.rds"))
saveRDS(glm_posterior, file.path("data", "raw", "glm_posterior.rds"))
saveRDS(glm_fits, file.path("data", "raw", "glm_fits.rds"))
