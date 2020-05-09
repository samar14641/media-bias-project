# Support functions that allow cnn to be scraped. There should only be function definitions in this file, nothing that gets executed

# 1: Returns ~a list of links where we can find links~ to news articles for the last x months
cnn_sitemap  <- function(last_x_months){
  
  sitemap        <- GET("https://www.cnn.com/sitemaps/cnn/index.xml") %>% read_html %>% html_nodes("loc") %>% html_text %>% .[str_detect(.,"www.cnn.com/sitemaps/article")]
  last_few_months   <- (today() %m-% months(last_x_months)) %--% today()
  articles_published <- sitemap %>% str_extract(pattern = "-.*.xml") %>% str_replace_all(pattern = "(^-|.xml)",replacement = "") %>% paste0("-01") %>% ymd()
  
  sitemap %>% subset(articles_published %within% last_few_months)
}


# 2: Given the results of the last function, visit each sitemap link and get a list of article links
cnn_find_links <- function(link){
  
  # Double check the right packages are loaded again for each worker when multi-threading
  suppressMessages(suppressWarnings({
    require(xml2)
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
  #article_links <- html_nodes(locs,"loc")        %>% html_text
  
  # Create a table of results containing information about the articles that month
  f <- data.table(link       = {sapply(locs, FUN = function(l){xml_child(l,search = 1) %>% html_text }) },
                  lastmod    = {sapply(locs, FUN = function(l){xml_child(l,search = 2) %>% html_text }) %>% as.Date},
                  changefreq = {sapply(locs, FUN = function(l){xml_child(l,search = 3) %>% html_text }) },
                  priority   = {sapply(locs, FUN = function(l){xml_child(l,search = 4) %>% html_text }) })[str_detect(link,pattern = ".html$")]
  
  f[, filed_under := {str_extract(link, pattern = "[0-9]/[A-Za-z]*?/[A-Za-z]") %>% str_replace_all(pattern = "(^[0-9]/|/[A-Za-z]$)", replacement = "")}]
  
}


# 3: Given the link to an article, visit it, collect data, return the data as a list or data.table
cnn_article <- function(link){
  
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
    
    results <- data.table(article_date     = { article %>% html_nodes(".update-time") %>% html_text %>% str_replace_all(pattern = "Updated ",replacement = "")},
                          article_headline = {article %>% html_node(".pg-headline") %>% html_text %>% str_trim  %>% str_c(collapse = "\n") %>% first},
                          article_author   = {article %>% html_nodes(".metadata__byline") %>% html_nodes("a") %>% html_text %>% str_c(collapse = ",")},
                          article_source   = {article %>% html_nodes(".el-editorial-source") %>% html_text() %>%
                              str_trim %>% str_replace_all(replacement = "",pattern = "(\\(|\\))")},
                          article_tag      = {NA},
                          article_text     = {article %>% html_nodes('section[data-zone-label="bodyText"]') %>% html_nodes('p')  %>% html_text %>% str_c(collapse = "\n")},
                          http_status_code = response[["status_code"]]) %>% .[1,]
    
    if(length(results$article_text) == 0){results$article_text   <- NA}
    if(is.na(results$article_source) | (length(results$article_source)==0)){ results$article_source <- "cnn" }
    
  },silent = TRUE)
  
  return(results)
  
}