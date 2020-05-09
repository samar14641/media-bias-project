library(tidyverse)
library(tidytext)

csvPath <- paste(getwd(), "ArticleData.csv", sep = "/")

dataset <- read_csv(csvPath) %>% select(1:13)

count(dataset, political_lean, news_site, sort = T) %>% mutate(news_site = reorder(news_site, n)) %>% ggplot(aes(x = news_site, y = n, fill = political_lean)) + geom_col() + coord_flip() + scale_fill_manual(values=c("darkgreen","darkblue", "darkred")) + labs(x = "News Site", y = "Number of Articles", fill = "Political Lean", title = "Number of Articles for each News Site broken down by Political Lean")

ggplot(dataset, aes(x = article_date, fill = political_lean)) + geom_bar() + scale_fill_manual(values=c("darkgreen","darkblue", "darkred")) + labs(x = "Article Date", y = "Number of Articles", fill = "Political Lean", title = "Number of Articles Published each Day broken down by Political Lean")

filter(dataset, news_site == "cnn") %>% select(link, article_date, article_headline, political_lean, news_site) %>% unnest_tokens(word, article_headline) %>% filter(!(word %in% stop_words$word)) %>% count(word, sort = T) %>% top_n(10, wt = n) %>% mutate(word = reorder(word, n)) %>% ggplot(aes(x = word, y = n, fill = word)) + geom_col(show.legend = FALSE) + coord_flip() + labs(x = "Term", y = "Count", title = "10 Most Common Terms in CNN's Headlines")
# select(dataset, link, article_date, article_headline, political_lean, news_site) %>% unnest_tokens(word, article_headline) %>% filter(!(word %in% stop_words$word)) %>% count(news_site, word, sort = T) %>% top_n(10, wt = n) %>% mutate(word = reorder(word, n)) %>% ggplot(aes(x = word, y = n, fill = news_site)) + geom_col(show.legend = FALSE) + coord_flip() + labs(x = "Term", y = "Count", title = "10 Most Common Terms in Headlines")

term = "Trump"
filter(dataset, str_detect(article_headline, regex("ukraine", ignore_case = TRUE))) %>% count(news_site, sort = TRUE) %>% mutate(news_site = reorder(news_site, n)) %>% ggplot(aes(x = news_site, y = n, fill = news_site)) + geom_col(show.legend = FALSE) + coord_flip() + labs(x = "News Site", y = "Count", title = "Occurrences of 'Ukraine' in a Headline")
select(dataset, link, article_date, article_headline, political_lean, news_site) %>% mutate(flag = ifelse(str_detect(article_headline, regex(term, ignore_case = TRUE)), 1, 0)) %>% count(political_lean, news_site, flag) %>% group_by(political_lean, news_site) %>% mutate(propr = n / sum(n)) %>% mutate(flag = ifelse(flag == 1, "Yes", "No")) %>% ggplot(aes(x = news_site, y = propr, fill = flag)) + geom_col() + facet_wrap(~ political_lean, scales = "free") + labs(x = "News Site", y = "Proportion of Articles", fill = paste("Does", term, "appear in\nthe headline?", sep = " "), title = paste("Proportion of Articles in which", term, "Appears in the Headline broken down by Political Lean", sep = " "))

# Dates with most articles: 2019-11-06, 2019-10-16, 2019-10-15, 2019-11-07, 2019-10-17, 2019-11-05
filter(dataset, article_date >= as.Date("5 November 2019", "%d %B %Y"), article_date <= as.Date("7 November 2019", "%d %B %Y")) %>% select(link, article_headline, news_site, political_lean) %>% unnest_tokens(word, article_headline) %>% filter(!(word %in% stop_words$word)) %>% count(political_lean, news_site, word, sort = T) %>% filter(n > 1) %>% mutate(word = reorder(word, n)) %>% group_by(political_lean, news_site) %>% top_n(3, wt = n) %>% ggplot(aes(x = word, y = n, fill = political_lean)) + geom_col() + coord_flip() + facet_wrap(~ news_site, scales = "free") + scale_fill_manual(values=c("darkgreen","darkblue", "darkred")) +labs(x = "Term", y = "Count", fill = "Political Lean", title = "Top 3 Most Commons Terms between 5th and 7th November 2019 broken down by News Site and Politcal Lean")
