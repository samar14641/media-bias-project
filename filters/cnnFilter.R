library(tidyverse)
library(stringr)

csvPath <- paste(getwd(), "news_scraper", "scraping_results", "cnn_results.csv", sep = "/")

cnnData <- read_csv(csvPath)

# Date format: yyyy-mm-dd
cnnData <- mutate(cnnData, article_date = lastmod)

# Take all articles filed under 'politics', remove articles without text, and then add the political lean and news site of the article
# Date filter: >= 1 August 2019
filteredCnnData <- filter(cnnData, filed_under == "politics", !is.na(article_text)) %>% mutate(political_lean = "left", news_site = "cnn") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))

# write_csv(filteredCnnData)