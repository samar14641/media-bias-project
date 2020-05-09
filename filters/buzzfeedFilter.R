library(tidyverse)
library(stringr)

csvPath <- paste(getwd(), "scraping", "BuzzfeedNews_Links.csv", sep = "/")

buzzfeedData <- read_csv(csvPath)

# Add missing columns and re-arrange order for binding later
buzzfeedData <- select(buzzfeedData, -X1, -collection_date) %>% mutate(changefreq = NA, priority = NA) %>% select(source:lastmod, changefreq:priority, filed_under:http_status_code) %>% mutate(collection_date = as.Date("11 November 2019", "%d %B %Y"), article_date = as.Date(article_date, "%B %d %Y"))
