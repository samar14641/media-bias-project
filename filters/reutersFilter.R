library(tidyverse)

csvPath <- paste(getwd(), "news_scraper", "scraping_results", "reuters_results.csv", sep = "/")

reutersData <- read_csv(csvPath)

# Date format: yyyy-mm-dd
reutersData <- mutate(reutersData, article_date = lastmod)

# Select articles tagged 'Politics', remove articles without text, and then add the political lean and news site of the article
# Date filter: >= 1 August 2019
filteredReutersData <- filter(reutersData, article_tag == "Politics", !is.na(article_text)) %>% mutate(political_lean = "centre", news_site = "reuters") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))

# We probably need more than 411 articles, but how??
# Note: Looks like Reuters doesn't archive data more than a month old
# write_csv(filteredData)