require(quanteda)

require(ggplot2)
require(ggthemes)

require(purrr)
require(data.table)

project_data<-fread("../ArticleData.csv")

# One of the motherjones articles returns NA (collection error) for readability. Its only one though, so I just skipped it
friendly_readability <- function(article_text){
  r<-NA
  try({
    r<-textstat_readability(article_text, measure = "Flesch.Kincaid")$Flesch[1]
  },silent = T)
  return(r)
}

project_data[,Flesch_Kincaid := map_dbl(article_text,friendly_readability)]

plot_this<-project_data[!is.na(Flesch_Kincaid)]


plot_this$political_lean <- factor(plot_this$political_lean, levels = c("right","centre","left"),ordered = TRUE)

guides_chart <- plot_this[Flesch_Kincaid <= 17][!is.na(Flesch_Kincaid),
                          .(political_lean = unique(political_lean),reading = mean(Flesch_Kincaid)), 
                          by = news_site][order(political_lean,reading)]

plot_this$news_site <- factor(plot_this$news_site, levels = guides_chart$news_site)

ggplot(plot_this,aes(x = news_site, y = Flesch_Kincaid, fill = political_lean)) + 
  geom_boxplot() + theme_fivethirtyeight() + coord_flip() + scale_fill_manual(values = c("darkred","seagreen","darkblue")) + 
  theme(legend.position = "none") + ggtitle("Article Reading Levels by Politics and Sites",subtitle = "Based on Flesch-Kincaid scale (approximates grade level)")



ggplot(plot_this[Flesch_Kincaid <= 17],aes(x = news_site, y = Flesch_Kincaid, fill = political_lean)) + 
  geom_boxplot() + theme_fivethirtyeight() + coord_flip() + scale_fill_manual(values = c("darkred","seagreen","darkblue")) + 
  theme(legend.position = "none", axis.text.y = element_text(face = "bold")) +
  ggtitle("Article Reading Levels by Politics and Sites",subtitle = "Based on Flesch-Kincaid scale. Excluding scores over 17") + 
  scale_y_continuous(breaks = c(0,4,8,12,16), labels = c("0 (No Schooling)","4(th Grade)","8 (Grade School Ed)","12 (High School Diploma)", "16 (Bachelor's Degree)"))


require(tidytext)
require(tokenizers)
require(RColorBrewer)

complex_words <- plot_this[order(-Flesch_Kincaid)][1:250] %>%
  unnest_tokens(words,article_text) %>% group_by(words) %>% summarize(counts = n()) %>%
  mutate(syl = nsyllable(words)) 

short_words <- function(article_text){
  paste(str_extract_all(article_text, '\\w{1,12}')[[1]], collapse=' ')
}

plot_this[,short_text := map_chr(article_text,short_words)]

plot_this[,Flesch_Kincaid2 := map_dbl(short_text,friendly_readability)]

guides_chart <- plot_this[!is.na(Flesch_Kincaid2),
                          .(political_lean = unique(political_lean),reading = mean(Flesch_Kincaid2)), 
                          by = news_site][order(political_lean,-reading)]

plot_this$news_site <- factor(plot_this$news_site, levels = guides_chart$news_site)

ggplot(plot_this,aes(x = news_site, y = Flesch_Kincaid2, fill = political_lean)) + 
  geom_boxplot() + theme_fivethirtyeight() + coord_flip() + scale_fill_manual(values = c("darkred","seagreen","darkblue")) + 
  theme(legend.position = "none", axis.text.y = element_text(face = "bold")) +
  ggtitle("Article Reading Levels by Politics and Sites",subtitle = "Based on Flesch-Kincaid scale. Excluding words longer than 12 characters.") + 
  scale_y_continuous(breaks = c(0,4,8,12,16), labels = c("0 (No Schooling)","4(th Grade)","8 (Grade School Ed)","12 (High School Diploma)", "16 (Bachelor's Degree)"))
