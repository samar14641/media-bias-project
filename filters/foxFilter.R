library(tidyverse)

csvPath <- paste(getwd(), "news_scraper", "scraping_results", "fox_results.csv", sep = "/")

foxData <- read_csv(csvPath)

# Date format: yyyy-mm-dd
foxData <- mutate(foxData, article_date = lastmod)  # Set the article date to the lastmod date as change freq for all is 0

# Take all articles filed under 'politics', remove articles without text, and then add the political lean and news site of the article
# Date filter: >= 1 August 2019
filteredFoxData <- filter(foxData, filed_under == "politics") %>% filter(!is.na(article_text)) %>% mutate(political_lean = "right", news_site = "fox") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))

# If we need more articles, we can explore articles filed under 'us'
# other potential articles: article_tag == '2020 Presidential Election', 'Donald Trump', 'Trump Impeachment Inquiry'

# write_csv(filedUnderPolitics)