library(tidyverse)
library(tidytext)
library(modelr)

csvPath <- paste(getwd(), "ArticleData.csv", sep = "/")

dataset <- read_csv(csvPath) %>% select(1:13) %>% filter(news_site == "cnn" | news_site == "fox", article_date > as.Date("10 August 2019", "%d %B %Y"), article_date < as.Date("7 November 2019", "%d %B %Y"))

ggplot(dataset, aes(x = article_date, fill = news_site)) + geom_bar() + scale_fill_manual(values=c("darkblue", "darkred")) + labs(x = "Date", y = "Articles Published", fill = "Source", title = "Articles Published by CNN and Fox")

imbalData <- select(dataset, link, article_date, article_headline, news_site, political_lean) %>% mutate(date = as.character(article_date)) %>% separate(date, into = c("year", "month", "day"), sep = "-") %>% select(-year, -day) %>% mutate(day = weekdays(article_date))

set.seed(123)
fox <- filter(imbalData, news_site == "fox")
cnn <- filter(imbalData, news_site == "cnn")
cnn <- resample(cnn, sample(nrow(cnn), 1859))
cnn <- as_tibble(cnn)
data <- rbind(cnn, fox)
ggplot(data, aes(x = article_date, fill = news_site)) + geom_bar() + scale_fill_manual(values=c("darkblue", "darkred")) + labs(x = "Date", y = "Articles Published", fill = "Source", title = "Articles Published by CNN and Fox")

count(data, news_site, day) %>% group_by(day) %>% mutate(propr = n / sum(n)) %>% ungroup() %>% mutate(day = factor(day, levels = rev(c("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")))) %>% ggplot(aes(x = day, y = propr, fill = news_site)) + geom_col() + coord_flip() + scale_fill_manual(values=c("darkblue", "darkred")) + labs(x = "Day", y = "Proportion of Articles", fill = "Source", title = "Proportion of Articles broken down by Day")

bigrams <- unnest_tokens(data, bigram, article_headline, token = "ngrams", n = 2) %>% separate(bigram, c("word1", "word2"), sep = " ") %>% filter(!(word1 %in% stop_words$word | word2 %in% stop_words$word)) %>% unite(bigram, word1, word2, sep = " ")
count(bigrams, news_site, day, bigram, sort = T) %>% group_by(day) %>% top_n(5, wt = n) %>% ungroup() %>% group_by(bigram) %>% mutate(propr = n / sum(n)) %>% ggplot(aes(x = bigram, y = propr, fill = news_site)) + geom_col() + coord_flip() + scale_fill_manual(values=c("darkblue", "darkred")) + labs(x = "Bigram", y = "Proportion of Usage", fill = "Source", title = "Proportion of Top 5 Bigrams of Each Day Used broken down by Source")

source_site = "cnn"
bigrams <- filter(dataset, news_site == source_site) %>% select(link, article_date, article_headline, political_lean, news_site) %>% unnest_tokens(bigram, article_headline, token = "ngrams", n = 2) %>% separate(bigram, c("word1", "word2"), sep = " ") %>% filter(!(word1 %in% stop_words$word | word2 %in% stop_words$word))
bigramGraph <- count(bigrams, word1, word2, sort = TRUE) %>% filter(n > 10) %>% graph_from_data_frame()
ggraph(bigramGraph, layout = "igraph",algorithm = "kk") + geom_edge_link() + geom_node_point() + geom_node_text(aes(label = name), vjust = 1, hjust = 1)
