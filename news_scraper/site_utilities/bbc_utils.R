# Support functions that allow bbc to be scraped. There should only be function definitions in this file, nothing that gets executed

# 1: Returns ~a list of links where we can find links~ to news articles for the last x months
## Reuter's pubic archive doesn't go very far back, only about a month. Grabbing every link and filtering by date as a result
bbc_sitemap  <- function(last_x_months){
  
  sitemap_links        <- GET("https://www.bbc.com/sitemaps/https-index-com-archive.xml") %>% read_html %>% html_nodes("loc") %>% html_text
  
  sitemap_links %>% tail(last_x_months*2)
  
}


# 2: Given the results of the last function, visit each sitemap link and get a list of article links
bbc_find_links <- function(link){
  
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
  ## Note: filter out any links to images. Similar problem might have occurred when scraping BBC
  image_links   <- locs %>% html_nodes("image") %>% html_text
  all_links     <- locs %>% html_nodes("loc") %>% html_text
  #article_links <- all_links[!(all_links %in% image_links)]
  
  # Getting the last modified date is incredibly annoying, but the article date is fairly good. Suggest later filtering on that instead during processing
  # Was able to do a fair bit of preliminary processing just using links: (1) only english language, (2) only news with "us-canada"
  f <- data.table(link       = {all_links},
                  lastmod    = {today()},
                  changefreq = {NA},
                  priority   = {NA})
  f<-f[!(link %in% image_links),]
  # Catch here to make sure articles are all english language
  f[, type := {str_extract(link, pattern = "bbc.com/.*?/") %>% str_replace_all(pattern = "(bbc.com/|/)", replacement = "")}]
  f <- f[type=="news",!"type"]
  f[, filed_under := {str_extract(link, pattern = "news/.*?[1-9]+") %>% str_replace_all(pattern = "(news/|-[1-9]+)", replacement = "")}]
  f[str_detect(filed_under,pattern = "us-canada"),]
}


# 3: Given the link to an article, visit it, collect data, return the data as a list or data.table
bbc_article <- function(link){
  
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
    
    results <- data.table(article_date     = {article %>% html_node(".date")     %>% html_attr("data-datetime")},
                          article_headline = {article %>% html_node(".story-body__h1") %>% html_text %>% str_trim  %>% str_c(collapse = "\n")},
                          article_author   = {NA}, # BBC appears to deliberately not include the reporter's name in the article
                          article_source   = {"bbc"},
                          article_tag      = {article %>% html_node(".tags-list")  %>% html_text %>% str_trim %>% str_c(collapse = "\n")},
                          article_text     = {article %>% html_nodes(".story-body__inner > p")%>% html_text %>% str_c(collapse = "\n") %>% trimws},
                          http_status_code = response[["status_code"]]) %>% .[1,]
    
    if(length(results$article_text) == 0){results$article_text   <- NA}
    if(is.na(results$article_source) | (length(results$article_source)==0)){ results$article_source <- "bbc" }
    
  },silent = TRUE)
  
  return(results)
  
}