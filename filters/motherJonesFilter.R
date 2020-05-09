library(tidyverse)

csvPath <- paste(getwd(), "news_scraper", "scraping_results", "motherjones_results.csv", sep = "/")

mjData <- read_csv(csvPath)

# Date format: yyyy-mm-dd
mjData <- mutate(mjData, article_date = lastmod)

# Rename 'Impeachapalooza' tags to 'Impeachment', select articles with certain tags, remove articles without text, and then add the political lean and news site of the article
# Date filter: >= 1 August 2019
filteredMjData <- mutate(mjData, article_tag = ifelse(article_tag == "Impeachapalooza" | article_tag == "Impeachapalooza\r\n\tPolitics", "Impeachment", article_tag)) %>% filter(article_tag == "Politics" | article_tag == "Impeachment" | article_tag == "Donald Trump") %>% filter(!is.na(article_text)) %>% mutate(political_lean = "left", news_site = "motherjones") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))

# write_csv(filteredData)