library(tidyverse)
library(tidytext)
library(igraph)
library(ggraph)

csvPath <- paste(getwd(), "ArticleData.csv", sep = "/")

dataset <- read_csv(csvPath) %>% select(1:13)

# Most common bigrams in a date range by politcal lean
startDate = "15"
endDate = "17"
month = "October"
bigrams <- filter(dataset, article_date >= as.Date(paste(startDate, month, "2019", sep = " "), "%d %B %Y"), article_date <= as.Date(paste(endDate, month, "2019", sep = " "), "%d %B %Y")) %>% select(link, article_date, article_headline, news_site, political_lean) %>% unnest_tokens(bigram, article_headline, token = "ngrams", n = 2) %>% separate(bigram, c("word1", "word2"), sep = " ") %>% filter(!(word1 %in% stop_words$word | word2 %in% stop_words$word))
# bigramCounts <- filter(dataset, article_date >= as.Date("5 November 2019", "%d %B %Y"), article_date <= as.Date("7 November 2019", "%d %B %Y")) %>% select(link, article_date, article_headline, news_site, political_lean) %>% unnest_tokens(bigram, article_headline, token = "ngrams", n = 2) %>% count(news_site, political_lean, bigram, sort = T)

count(bigrams, political_lean, word1, word2, sort = TRUE) %>% filter(n > 4) %>% unite(bigram, word1, word2, sep = " ") %>% mutate(bigram = factor(bigram, levels = rev(unique(bigram)))) %>% ggplot(aes(x = bigram, y = n, fill = political_lean)) + geom_col() + coord_flip() + scale_fill_manual(values=c("darkgreen","darkblue", "darkred")) + labs(x = "Bigram", y = "Count", fill = "Political Lean", title = paste("Most Common Headline Bigrams between", paste(startDate, "th", sep = ""), "and", paste(endDate, "th", sep = ""), month, "2019\nbroken down by Political Lean", sep = " "))

bigramGraph <- count(bigrams, word1, word2, sort = TRUE) %>% filter(n > 2) %>% graph_from_data_frame()
ggraph(bigramGraph, layout = "igraph", algorithm = "kk") + geom_edge_link() + geom_node_point() + geom_node_text(aes(label = name), vjust = 1, hjust = 1) 
# ------------------------------------------

# Headline tfidf 
bigrams <- select(dataset, link, article_date, article_headline, news_site, political_lean) %>% unnest_tokens(bigram, article_headline, token = "ngrams", n = 2) %>% separate(bigram, c("word1", "word2"), sep = " ") %>% filter(!(word1 %in% stop_words$word | word2 %in% stop_words$word)) %>% unite(bigram, word1, word2, sep = " ")
words <- select(dataset, link, article_date, article_headline, news_site, political_lean) %>% unnest_tokens(word, article_headline) %>% anti_join(stop_words, by = "word")

# Overall most common bigrams/words by political lean
count(bigrams, political_lean, bigram, sort = T) %>% group_by(political_lean) %>% top_n(10, wt = n) %>% ungroup() %>% mutate(bigram = reorder(bigram, n)) %>% ggplot(aes(x = bigram, y = n, fill = political_lean)) + geom_col() + coord_flip() + scale_fill_manual(values=c("darkgreen","darkblue", "darkred")) + labs(x = "Bigram", y = "Count", fill = "Political Lean", title = "Overall Most Common Bigrams broken down by Political Lean")
count(words, political_lean, word, sort = T) %>% group_by(political_lean) %>% top_n(10, wt = n) %>% ungroup() %>% mutate(word = reorder(word, n)) %>% ggplot(aes(x = word, y = n, fill = political_lean)) + geom_col() + coord_flip() + scale_fill_manual(values=c("darkgreen","darkblue", "darkred")) + labs(x = "Word", y = "Count", fill = "Political Lean", title = "Overall Most Common Words broken down by Political Lean")

#tfidf excluding centre
filter(bigrams, !(political_lean == "centre")) %>% count(political_lean, bigram, sort = T) %>% bind_tf_idf(bigram, political_lean, n) %>% arrange(-idf) %>% group_by(political_lean) %>% top_n(15, wt = tf_idf) %>% ungroup() %>% mutate(bigram = reorder(bigram, tf_idf)) %>% ggplot(aes(x = bigram, y = tf_idf, fill = political_lean)) + geom_col() + coord_flip() + facet_wrap(~ political_lean, scales = "free") + scale_fill_manual(values=c("darkblue", "darkred")) + labs(x = "Bigram", y = "tf-idf Score", fill = "Political Lean", title = "tf-ifd Scores of Article Headline Bigrams")
filter(words, !(political_lean == "centre")) %>% count(political_lean, word, sort = T) %>% bind_tf_idf(word, political_lean, n) %>% arrange(-idf) %>% group_by(political_lean) %>% top_n(15, wt = tf_idf) %>% ungroup() %>% mutate(word = reorder(word, tf_idf)) %>% ggplot(aes(x = word, y = tf_idf, fill = political_lean)) + geom_col() + coord_flip() + facet_wrap(~ political_lean, scales = "free") + scale_fill_manual(values=c("darkblue", "darkred")) + labs(x = "Word", y = "tf-idf Score", fill = "Political Lean", title = "tf-ifd Scores of Article Headline Words")
