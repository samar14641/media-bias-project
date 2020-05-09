news_scraper <- function(last_x_months = 3,
                         use_cores     = 3,
                         news_sites    = "fivethirtyeight",
                         max_pages     = NULL){
  ############################################################################
  # Load Packages
  #############################################################################
  # Working with data. Magrittr -> more pipe functions, data.table -> speed
  require(magrittr)
  require(dplyr)
  require(data.table)
  # Web crawling tools
  require(rvest)
  require(httr)
  # Working with/fixing strings
  require(stringr)
  # Working with dates
  require(lubridate)
  # Simple Multithreading
  require(furrr)

  # If more than one news site is passed to the function, iterate through them and return the result as a list of tables (named by site)
  if(length(news_sites)>1){

    results <- lapply(news_sites,FUN = function(news){

      news_scraper(last_x_months = last_x_months,
                   use_cores     = use_cores,
                   news_sites    = news,
                   max_pages     = max_pages)
    }) %>% set_names(news_sites)

    return(results)
  }

  # Load in support functions to the global environment
  site_utilities <- list.files("site_utilities",pattern = news_sites,full.names = T)
  source(site_utilities)


  # Get functions appropriate for the target site
  sitemap_function <- match.fun(str_c(news_sites,"sitemap",sep="_"))
  find_links       <- match.fun(str_c(news_sites,"find_links",sep="_"))
  article          <- match.fun(str_c(news_sites,"article",sep="_"))


  ##########################################################################################################
  # Find the links to the pages containing the last 'x' months articles as specified, using the sitemap
  #########################################################################################################

  sitemap_links  <- sitemap_function(last_x_months)


  ############################################################################################################
  # This loops through the links to past articles on the sitemap, which appear to go more or less by month
  ##########################################################################################################
  if(use_cores > availableCores()){
    warning("Selected more cores than are available, running sequentially.")
    plan("sequential")
  } else if(use_cores == 1){
    plan("sequential")
  } else{
    plan(tweak(multiprocess, workers = use_cores))
  }


  # Messages
  cat(rep("=",125),"\n\n\n",sep = "")
  cat("\tTarget Site: ",news_sites,"\n")
  cat("\tCPU Cores to be used: ",use_cores,"\n\n")
  cat("Collecting links ...\n")

  news_results <- future_map(sitemap_links, .f = find_links,.progress = TRUE) %>%
    set_names(sitemap_links) %>%
    rbindlist(idcol = "source") %>%
    arrange(desc(lastmod)) %>%
    filter(today() - lastmod <= last_x_months*31) %>% filter(!duplicated(link)) %>%
    as.data.table

  # Make sure the results aren't over the limit of returned articles (if selected)
  if(!is.null(max_pages)){
    if(nrow(news_results)>max_pages){
      news_results <- news_results %>% head(max_pages)
    }
  }

  # Messages
  cat("\tComplete!\n")
  cat("\tNumber of links found:",length(news_results$link),"\n")
  min_date <- min(news_results$lastmod)
  max_date <- max(news_results$lastmod)
  cat("\tApproximate Date Range: ",as.character(min_date),"--",as.character(max_date)," (",as.character(max_date - min_date)," days)"
      ,"\n\n",sep = "")

  news_results[,.(number_of_links = .N),by = filed_under] %>% setorder(-number_of_links) %>% print
  cat("\n\n")

  ##################################################
  # Get features from articles
  ###################################################
  # With a function to scrape an article given a link, we can multi-thread it.
  # The function returns 5 results in the order specified in the list,
  # so we need to create 5 columns to hold the output. It is (slightly) faster to use data.table's := (does the same as mutate),
  # and more importantly it can accept functions that have multiple outputs and map them to multiple columns as you specify

  # Messages
  cat("Collecting article data now...\n")

  news_results[,c("article_date","article_headline","article_author","article_source","article_tag","article_text","http_status_code") :=
  {future_map(link,.f = article,.progress = TRUE) %>% rbindlist(fill = TRUE)}]

  # Messages
  cat("\tComplete!\n\n")
  cat(rep("=",125),"\n\n\n",sep = "")
  # Reset the multithreading plan
  plan("sequential")

  # Add collection date
  news_results[,collection_date := now()]

  return(news_results)
}


# Important note: 
# list.dirs("site_utilities") should work and not return an error. If it does, use getwd() and setwd() to change to the right working directory.
# The scraper will fail unless you are in the same working directory as news_scraper_main.R
#setwd("C:/Users/Owner/Desktop/Work/Data Management And Processing/Project/Group_Project/news_scraper")

# test
news <- news_scraper(news_sites = c("fivethirtyeight","fox","reuters","motherjones"),use_cores = 3, last_x_months = 3)


bbc_news <- news_scraper(news_sites = "bbc",use_cores = 7,last_x_months = 3)


cnn_news <- news_scraper(news_sites = "cnn",use_cores = 5,last_x_months = 4)




require(quanteda)
project_data<-fread("../ArticleData.csv")

data_friendly_readability <- function(article_text){
  r <- NA
  try({
    r <- textstat_readability(article_text, measure = "Flesch.Kincaid")$Flesch[1]
  },silent = T)
  return(r)
}

reading_levels<-textstat_readability(project_data$article_text, measure = "Flesch.Kincaid")
project_data[,Flesch_Kincaid := map_dbl(article_text,data_friendly_readability)]

ggplot(project_data,aes(x = Flesch_Kincaid, fill = news_site)) + geom_bar() + theme_fivethirtyeight()




#### Fixing Script tag issues in the project data (added  `%>% html_nodes('p') %>%` in CNN utils file line #86)
require(purrr)
project_data<-fread("../ArticleData.csv")
problems <- project_data[,.(num_script_problems = sum(grepl("(jQuery|containerid|jpg)",article_text))), by = news_site]


redo_links <-project_data[grepl("(jQuery|containerid)",article_text)]$link
plan(strategy = multiprocess)
redo_articles <- future_map(redo_links,cnn_article,.progress = T)%>% set_names(redo_links) %>% rbindlist(idcol = "link")

project_data2<-project_data

for(i in seq(nrow(redo_articles))){
  project_data2[link == redo_articles$link[i],article_text := redo_articles$article_text[i]]
}

remaining_problems <-project_data2[,.(num_script_problems_old = sum(grepl("(jQuery|containerid|jpg)",article_text)),
                   
                                                         num_script_problems_now = sum(grepl("(jQuery|containerid)",article_text2))), by = news_site]
project_data$article_text2<-NULL
fwrite(project_data2,"../ArticleData.csv")

