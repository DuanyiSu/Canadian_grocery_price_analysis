#### Preamble ####
# Purpose: To explore and visualize trends in pricing data, perform Bayesian modeling, and conduct posterior predictive checks.
# Author: Duanyi Su
# Date: 3 December 2024
# Contact: duanyi.su@mail.utoronto.ca
# License: MIT
# Pre-requisites: 
#   - Ensure the `tidyverse`, `rstanarm`, `bayesplot`, `arrow`, and `here` packages are installed.
#   - Ensure the cleaned dataset and model are available.

#### Workspace setup ####
library(tidyverse)
library(rstanarm)
library(bayesplot)
library(arrow)
library(here)

#### Load data ####
data_parquet <- read_parquet(here("data", "02-analysis_data", "data.parquet"))

#### Bayesian Model ####
# Define Bayesian model
data_model <- stan_glm(
  formula = current_price ~ old_price + vendor + month,
  data = data_parquet,
  family = gaussian(),
  prior = normal(location = 0, scale = 2.5, autoscale = TRUE),
  prior_intercept = normal(location = 0, scale = 2.5, autoscale = TRUE),
  prior_aux = exponential(rate = 1, autoscale = TRUE),
  seed = 304
)

#### Save model ####
saveRDS(
  data_model,
  file = here("models", "data_model.rds")
)

#### Visualization and Analysis ####

# Chart 1: Distribution of Current Price
ggplot(data_parquet, aes(x = current_price)) +
  geom_histogram(binwidth = 1, fill = "lightgrey", color = "darkgrey", alpha = 0.7) +
  geom_density(aes(y = ..count..), color = "red", size = 1) +
  labs(title = "Distribution of Current Prices", x = "Current Price (in $)", y = "Frequency") +
  theme_minimal()

# Chart 2: Price Difference by Vendor
data_parquet <- data_parquet %>%
  mutate(price_difference = old_price - current_price)

ggplot(data_parquet, aes(x = vendor, y = price_difference)) +
  geom_boxplot(fill = "lightgrey", color = "darkgrey", alpha = 0.7) +
  labs(title = "Price Difference by Vendor", x = "Vendor", y = "Price Difference (in $)") +
  theme_minimal()

# Chart 3: Average Current Price Over Time
data_parquet <- data_parquet %>%
  mutate(date = as.Date(paste(year, month, day, sep = "-"), format = "%Y-%m-%d"))

avg_price_per_date <- data_parquet %>%
  group_by(date) %>%
  summarise(avg_current_price = mean(current_price, na.rm = TRUE))

ggplot(avg_price_per_date, aes(x = date, y = avg_current_price)) +
  geom_line(color = "darkgrey", size = 1) +
  labs(title = "Average Current Price Over Time", x = "Date", y = "Average Current Price (in $)") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# Chart 4: Relationship Between Old and Current Prices
ggplot(data_parquet, aes(x = old_price, y = current_price)) +
  geom_point(color = "lightgrey", alpha = 0.7) +
  geom_smooth(method = 'loess', color = "darkgrey", fill = "red", alpha = 0.8, se = TRUE) +
  labs(title = "Old Price vs. Current Price", x = "Old Price (in $)", y = "Current Price (in $)") +
  theme_minimal()

# Chart 5: Distribution of Unit Prices
ggplot(data_parquet, aes(x = price_per_unit)) +
  geom_histogram(binwidth = 0.1, fill = "lightgrey", color = "darkgrey", alpha = 0.7) +
  geom_density(aes(y = after_stat(count)), color = "red", linewidth = 1) +
  labs(title = "Distribution of Unit Prices", x = "Unit Price ($ per 100 grams)", y = "Frequency") +
  theme_minimal()

#### Posterior Predictive Check ####
# Posterior predictive check for the Bayesian model
pp_check(data_model) +
  ggtitle("Posterior Predictive Check for Data Model")

#### Model Summary ####
summary(data_model)
