library(tidyverse)
library(stringr)

csvPath <- paste(getwd(), "scraping", "Vox_Links.csv", sep = "/")

voxData <- read_csv(csvPath)

# Add missing columns and re-arrange order for binding later
voxData <- select(voxData, -X1, -collection_date) %>% mutate(changefreq = NA, priority = NA) %>% select(source:lastmod, changefreq:priority, filed_under:http_status_code) %>% mutate(collection_date = as.Date("18 November 2019", "%d %B %Y"), article_date = as.Date(article_date, "%B %d %Y"))

# Date filter: >= 1 August 2019
filteredVoxData <- filter(voxData, str_detect(article_tag, regex("politics", ignore_case = TRUE)), !is.na(article_text)) %>% mutate(political_lean = "left", news_site = "vox") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))

# write_csv(filteredVoxData)