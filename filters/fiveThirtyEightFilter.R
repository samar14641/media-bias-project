library(tidyverse)

csvPath <- paste(getwd(), "news_scraper", "scraping_results", "fivethirtyeight_results.csv", sep = "/")

fteData <- read_csv(csvPath)

# Date format: yyyy-mm-dd
fteData <- mutate(fteData, article_date = lastmod)

# Take all articles with tags below, remove articles without text, and then add the political lean and news site of the article
# Date filter: >= 1 August 2019
filteredFteData <- filter(fteData, article_tag == "2020 Election" | article_tag == "Impeachment" | article_tag == "2020 Senate Elections" | article_tag == "The Trump Administration" | article_tag == "Congress" | article_tag == "2020 Democratic Primary" | article_tag == "2020 Republican Primary" | article_tag == "Donald Trump") %>% filter(!is.na(article_text)) %>% mutate(political_lean = "centre", news_site = "fivethirtyeight") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))

# write_csv(filteredData)