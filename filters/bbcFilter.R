library(tidyverse)
library(stringr)

csvPath <- paste(getwd(), "news_scraper", "scraping_results", "bbc_results.csv", sep = "/")

bbcData <- read_csv(csvPath)

missingDates <- filter(bbcData, is.na(article_date)) %>% mutate(article_date = lastmod)
bbcData <- anti_join(bbcData, missingDates, by = "link") %>% mutate(article_date = as.Date(article_date, "%d %B %Y"))
bbcData <- rbind(bbcData, missingDates)

# Date filter: >= 1 August 2019
filteredBbcData <- filter(bbcData, str_detect(article_tag, regex("trump|US election|ukraine|whistleblower|impeachment", ignore_case = TRUE)), !is.na(article_text)) %>% mutate(political_lean = "centre", news_site = "bbc") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))

# write_csv(filteredData)