# Support functions that allow motherjones to be scraped. There should only be function definitions in this file, nothing that gets executed

# 1: Returns ~a list of links where we can find links~ to news articles for the last x months
## For this its "https://motherjones.com/sitemap-index-1.xml", and the links we want are at the tail end of that list of links
motherjones_sitemap  <- function(last_x_months){
  
  sitemap        <- GET("https://motherjones.com/sitemap-index-1.xml") %>% read_html %>% html_nodes("loc") %>% html_text
  sitemap_links  <- sitemap %>% tail(last_x_months*2) # Each individual sitemap seems to cover ~1-2 months
  
}


# 2: Given the results of the last function, visit each sitemap link and get a list of article links
motherjones_find_links <- function(link){
  
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
  return(f) 
}

# 3: Given the link to an article, visit it, collect data, return the data as a list or data.table
motherjones_article <- function(link){
  
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
    
    results <- data.table(article_date     = {article %>% html_node(".dateline")  %>% html_text %>% str_trim  %>% str_c(collapse = "\n")},
                          article_headline = {article %>% html_node(".entry-title")    %>% html_text %>% str_trim %>% str_c(collapse = "\n") %>% first},
                          article_author   = {article %>% html_nodes('a[data-ga-label="authorName"]')  %>% html_text   %>% str_trim  %>% str_c(collapse = ",")},
                          article_source   = {"MotherJones"},
                          article_tag      = {article %>% html_node('.post-categories')  %>% html_text %>% str_trim %>% str_c(collapse = "\n")},
                          article_text     = {article %>% html_nodes(".entry-content > p")  %>% html_text %>% str_trim %>% str_c(collapse = "\n")},
                          http_status_code = response[["status_code"]]) %>% .[1,]
    
    if(length(results$article_text) == 0){results$article_text   <- NA}
    
  },silent = TRUE)
  
  
  return(results)
  
}

