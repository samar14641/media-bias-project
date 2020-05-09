library(tidyverse)
library(stringr)

# BBC
csvPath <- paste(getwd(), "news_scraper", "scraping_results", "bbc_results.csv", sep = "/")

bbcData <- read_csv(csvPath)

missingDates <- filter(bbcData, is.na(article_date)) %>% mutate(article_date = lastmod)
bbcData <- anti_join(bbcData, missingDates, by = "link") %>% mutate(article_date = as.Date(article_date, "%d %B %Y"))
bbcData <- rbind(bbcData, missingDates)

# Date filter: >= 1 August 2019
filteredBbcData <- filter(bbcData, str_detect(article_tag, regex("trump|US election|ukraine|whistleblower|impeachment", ignore_case = TRUE)), !is.na(article_text)) %>% mutate(political_lean = "centre", news_site = "bbc") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))
# ------------------------------------------

# BREITBART
csvPath <- paste(getwd(), "scraping", "Breitbart_Links.csv", sep = "/")

breitbartData <- read_csv(csvPath)

# Add missing columns and re-arrange order for binding later
breitbartData <- select(breitbartData, -X1, -collection_date) %>% mutate(changefreq = NA, priority = NA) %>% select(source:lastmod, changefreq:priority, filed_under:http_status_code) %>% mutate(collection_date = as.Date("8 November 2019", "%d %B %Y"), article_date = as.Date(article_date, "%d %B %Y"))

# Date filter: >= 1 August 2019
filteredBreitbartData <- filter(breitbartData, str_detect(article_tag, regex("trump|2020", ignore_case = TRUE)), !is.na(article_text)) %>% mutate(political_lean = "right", news_site = "breitbart") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))
# ------------------------------------------

# BUZZFEED

# ------------------------------------------

# CNN
csvPath <- paste(getwd(), "news_scraper", "scraping_results", "cnn_results.csv", sep = "/")

cnnData <- read_csv(csvPath)

# Date format: yyyy-mm-dd
cnnData <- mutate(cnnData, article_date = lastmod)

# Take all articles filed under 'politics', remove articles without text, and then add the political lean and news site of the article
# Date filter: >= 1 August 2019
filteredCnnData <- filter(cnnData, filed_under == "politics", !is.na(article_text)) %>% mutate(political_lean = "left", news_site = "cnn") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))
# ------------------------------------------

# FIVETHIRTYEIGHT
csvPath <- paste(getwd(), "news_scraper", "scraping_results", "fivethirtyeight_results.csv", sep = "/")

fteData <- read_csv(csvPath)

# Date format: yyyy-mm-dd
fteData <- mutate(fteData, article_date = lastmod)

# Take all articles with tags below, remove articles without text, and then add the political lean and news site of the article
# Date filter: >= 1 August 2019
filteredFteData <- filter(fteData, article_tag == "2020 Election" | article_tag == "Impeachment" | article_tag == "2020 Senate Elections" | article_tag == "The Trump Administration" | article_tag == "Congress" | article_tag == "2020 Democratic Primary" | article_tag == "2020 Republican Primary" | article_tag == "Donald Trump") %>% filter(!is.na(article_text)) %>% mutate(political_lean = "centre", news_site = "fivethirtyeight") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))
# ------------------------------------------

# FOX
csvPath <- paste(getwd(), "news_scraper", "scraping_results", "fox_results.csv", sep = "/")

foxData <- read_csv(csvPath)

# Date format: yyyy-mm-dd
foxData <- mutate(foxData, article_date = lastmod)  # Set the article date to the lastmod date as change freq for all is 0

# Take all articles filed under 'politics', remove articles without text, and then add the political lean and news site of the article
# Date filter: >= 1 August 2019
filteredFoxData <- filter(foxData, filed_under == "politics") %>% filter(!is.na(article_text)) %>% mutate(political_lean = "right", news_site = "fox") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))
# ------------------------------------------

# MOTHERJONES
csvPath <- paste(getwd(), "news_scraper", "scraping_results", "motherjones_results.csv", sep = "/")

mjData <- read_csv(csvPath)

# Date format: yyyy-mm-dd
mjData <- mutate(mjData, article_date = lastmod)

# Rename 'Impeachapalooza' tags to 'Impeachment', select articles with certain tags, remove articles without text, and then add the political lean and news site of the article
# Date filter: >= 1 August 2019
filteredMjData <- mutate(mjData, article_tag = ifelse(article_tag == "Impeachapalooza" | article_tag == "Impeachapalooza\r\n\tPolitics", "Impeachment", article_tag)) %>% filter(article_tag == "Politics" | article_tag == "Impeachment" | article_tag == "Donald Trump") %>% filter(!is.na(article_text)) %>% mutate(political_lean = "left", news_site = "motherjones") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))
# ------------------------------------------

# REUTERS
csvPath <- paste(getwd(), "news_scraper", "scraping_results", "reuters_results.csv", sep = "/")

reutersData <- read_csv(csvPath)

# Date format: yyyy-mm-dd
reutersData <- mutate(reutersData, article_date = lastmod)

# Select articles tagged 'Politics', remove articles without text, and then add the political lean and news site of the article
# Date filter: >= 1 August 2019
filteredReutersData <- filter(reutersData, article_tag == "Politics", !is.na(article_text)) %>% mutate(political_lean = "centre", news_site = "reuters") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))
# ------------------------------------------

# VOX
csvPath <- paste(getwd(), "scraping", "Vox_Links.csv", sep = "/")

voxData <- read_csv(csvPath)

# Add missing columns and re-arrange order for binding later
voxData <- select(voxData, -X1, -collection_date) %>% mutate(changefreq = NA, priority = NA) %>% select(source:lastmod, changefreq:priority, filed_under:http_status_code) %>% mutate(collection_date = as.Date("18 November 2019", "%d %B %Y"), article_date = as.Date(article_date, "%B %d %Y"))

# Date filter: >= 1 August 2019
filteredVoxData <- filter(voxData, str_detect(article_tag, regex("politics", ignore_case = TRUE)), !is.na(article_text)) %>% mutate(political_lean = "left", news_site = "vox") %>% filter(article_date >= as.Date("1 August 2019", "%d %B %Y"))
# ------------------------------------------

# Bind data, and remove article_source (use news_site column!)
dataset <- rbind(filteredBbcData, filteredBreitbartData, filteredCnnData, filteredFoxData, filteredFteData, filteredMjData, filteredReutersData, filteredVoxData) %>% select(-changefreq, -priority, -article_source)

write_csv(dataset, paste(getwd(), "ArticleData.csv", sep = "/"))
