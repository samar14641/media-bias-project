# Support functions that allow Fox to be scraped. There should only be function definitions in this file, nothing that gets executed

# 1: Returns ~a list of links where we can find links~ to news articles for the last x months
fox_sitemap  <- function(last_x_months){
  
  sitemap        <- GET("https://www.foxnews.com/sitemap.xml") %>% read_html %>% html_nodes("loc") %>% html_text
  sitemap_links  <- subset(sitemap,str_detect(sitemap,"&from=")) %>% tail(last_x_months*3)
  
}


# 2: Given the results of the last function, visit each sitemap link and get a list of article links
fox_find_links <- function(link){
  
  # Double check the right packages are loaded again for each worker when multi-threading
  suppressMessages(suppressWarnings({
    require(magrittr)
    require(dplyr)
    require(data.table)
    require(rvest)
    require(httr)
    require(stringr)
    require(lubridate)
    require(furrr)
  }))
  
  # Get html from the sitemap link
  locs <- GET(link) %>% read_html %>% html_nodes("url")
  
  # Create a table of results containing information about the articles that month
  f <- data.table(link       = {html_nodes(locs,"loc")        %>% html_text},
                  lastmod    = {html_nodes(locs,"lastmod")    %>% html_text %>% as.Date},
                  changefreq = {html_nodes(locs,"changefreq") %>% html_text},
                  priority   = {html_nodes(locs,"priority")   %>% html_text})
  
  f[, filed_under := {str_extract(link, pattern = ".com/.*?/") %>% str_replace_all(pattern = "(.com/|/)", replacement = "")}]
  
}


# 3: Given the link to an article, visit it, collect data, return the data as a list or data.table
fox_article <- function(link){
  
  # Double check the right packages are loaded again for each worker when multi-threading
  suppressMessages(suppressWarnings({
    require(magrittr)
    require(dplyr)
    require(data.table)
    require(rvest)
    require(httr)
    require(stringr)
    require(lubridate)
    require(furrr)
  }))
  
  
  
  response <- GET(link) 
  
  
  # Use try() for more error catching (i.e. bad link, connection timeout, coding error, etc.)
  ## Create a list of results to return if collection fails
  results <- data.table(article_date     = NA,
                        article_headline = NA,
                        article_author   = NA,
                        article_source   = NA,
                        article_tag      = NA,
                        article_text     = NA,
                        http_status_code = response[["status_code"]])
  ## Attempt to collect data from the page, return results as a data.table with 1 row
  try({
    # Actual data collection
    article <- response %>% read_html()
    
    results <- data.table(article_date     = {article %>% html_node(".article-date > time")    %>% html_text %>% str_trim %>% str_c(collapse = "\n")},
                          article_headline = {article %>% html_node(".headline") %>% html_text %>% str_trim  %>% str_c(collapse = "\n") %>% first},
                          article_author   = {article %>% html_nodes(".author-byline > span")  %>% html_nodes('a') %>% html_text %>%
                               str_c(collapse = "\n") %>% first %>% str_replace_all(pattern = "\n \\| Fox News",replacement = "")},
                          article_source   = {article %>% html_node(".article_source")         %>% html_text %>% str_trim %>% str_c(collapse = "\n")},
                          article_tag      = {article %>% html_node(".eyebrow")                %>% html_text %>% str_trim %>% str_c(collapse = "\n")},
                          article_text     = {article %>% html_nodes(".article-body > p")      %>% html_text %>% str_c(collapse = "\n")},
                          http_status_code = response[["status_code"]]) %>% .[1,]
    
    if(length(results$article_text) == 0){results$article_text   <- NA}
    if(is.na(results$article_source) | (length(results$article_source)==0)){ results$article_source <- "Fox" }
    
  },silent = TRUE)
  
  return(results)
  
}

