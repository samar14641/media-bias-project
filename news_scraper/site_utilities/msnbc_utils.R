# Note:
###### Not sure if this should be used. I realized after writing this that it there are only archives available for the Maddow Blogit seems, not the whole site.



# Support functions that allow msnbc to be scraped. There should only be function definitions in this file, nothing that gets executed

# 1: Returns ~a list of links where we can find links~ to news articles for the last x months
## For this its "http://www.msnbc.com/sitemap/msnbc/sitemap-index", and the links we want are at the tail end of that list of links
msnbc_sitemap  <- function(last_x_months){
  
  sitemap        <- GET("http://www.msnbc.com/sitemap/msnbc/sitemap-index") %>% read_html %>% html_nodes("loc") %>% html_text
  sitemap_links  <- sitemap  %>% .[str_detect(string = .,pattern = "article")] %>% head(last_x_months) 
  

  
}


# 2: Given the results of the last function, visit each sitemap link and get a list of article links
msnbc_find_links <- function(link){
  
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
                  changefreq = NA,
                  priority   = NA)
  
  f[, filed_under := {str_extract(link, pattern = ".com/.*?/") %>% str_replace_all(pattern = "(.com/|/)", replacement = "")}]
  #f <- f %>% filter(filed_under=="features") %>% as.data.table
  return(f) 
}

# 3: Given the link to an article, visit it, collect data, return the data as a list or data.table
msnbc_article <- function(link){
  
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
    
    results <- data.table(article_date     = {article %>% html_node(".field-name-field-publish-date > time")  %>% html_text %>% str_trim  %>% str_c(collapse = "\n")},
                          article_headline = {article %>% html_node(".pane-node-title")    %>% html_text %>% str_trim %>% str_c(collapse = "\n") %>% first},
                          article_author   = {article %>% html_node(".author")  %>% html_text   %>% str_trim  %>% str_c(collapse = "\n")},
                          article_source   = {article %>% html_node(".panel__main__content > meta[itemprop='sourceOrganization']") %>% html_attr("content")},
                          article_tag      = {article %>% html_nodes(".issues-topics")  %>% html_text %>% str_trim %>% str_c(collapse = ",")},
                          article_text     = {article %>% html_node('div[itemprop="articleBody"]')  %>% html_text %>% str_trim %>% str_c(collapse = "\n")},
                          http_status_code = response[["status_code"]]) %>% .[1,]
    
    if(length(results$article_text) == 0){results$article_text   <- NA}
    
  },silent = TRUE)
  
  
  return(results)
  
}
