library(tidyverse)
library(stringr)

csvPath <- paste(getwd(), "scraping", "Breitbart_Links.csv", sep = "/")

breitbartData <- read_csv(csvPath)

# Add missing columns and re-arrange order for binding later
breitbartData <- select(breitbartData, -X1, -collection_date) %>% mutate(changefreq = NA, priority = NA) %>% select(source:lastmod, changefreq:priority, filed_under:http_status_code) %>% mutate(collection_date = as.Date("8 November 2019", "%d %B %Y"), article_date = as.Date(article_date, "%d %B %Y"))

# Date filter: >= 1 August 2019
filteredBreitbartData <- filter(breitbartData, str_detect(article_tag, regex("trump|2020", ignore_case = TRUE)), !is.na(article_text)) %>% mutate(political_lean = "right", news_site = "breitbart") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))

# write_csv(filteredData)