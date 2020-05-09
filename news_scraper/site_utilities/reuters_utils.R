# Support functions that allow reuters to be scraped. There should only be function definitions in this file, nothing that gets executed

# 1: Returns ~a list of links where we can find links~ to news articles for the last x months
## Reuter's pubic archive doesn't go very far back, only about a month. Grabbing every link and filtering by date as a result
reuters_sitemap  <- function(last_x_months){
  
  sitemap_links        <- GET("https://www.reuters.com/sitemap_index.xml") %>% read_html %>% html_nodes("loc") %>% html_text
  
}


# 2: Given the results of the last function, visit each sitemap link and get a list of article links
reuters_find_links <- function(link){
  
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
  article_links <- all_links[!(all_links %in% image_links)]
  
  f <- data.table(link       = {article_links},
                  lastmod    = {html_nodes(locs,"lastmod")    %>% html_text %>% as.Date},
                  changefreq = {html_nodes(locs,"changefreq") %>% html_text},
                  priority   = {NA})
  
  f[, filed_under := {str_extract(link, pattern = "article/.*?/") %>% str_replace_all(pattern = "(article/|/)", replacement = "")}]
  
}


# 3: Given the link to an article, visit it, collect data, return the data as a list or data.table
reuters_article <- function(link){
  
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
    # Several reuters articles have no authors listed at all, this is an error catch
    article_author <- article %>% html_nodes(".Attribution_content")   %>% html_text %>% str_extract("Reporting by .*?;") %>% str_replace_all("(Reporting by |;)", "")
    if(length(article_author) == 0){article_author<-NA}
    
    results <- data.table(article_date     = {article %>% html_node(".ArticleHeader_date")     %>% html_text %>% str_extract("^.*?/") %>% str_replace(" /","") %>% str_trim %>% str_c(collapse = "\n")},
                          article_headline = {article %>% html_node(".ArticleHeader_headline") %>% html_text %>% str_trim  %>% str_c(collapse = "\n")},
                          article_author   = {article_author},
                          article_source   = {"Reuters"},
                          article_tag      = {article %>% html_node(".ArticleHeader_channel")  %>% html_text %>% str_trim %>% str_c(collapse = "\n")},
                          article_text     = {article %>% html_nodes(".StandardArticleBody_body > p")%>% html_text %>% str_c(collapse = "\n")},
                          http_status_code = response[["status_code"]]) %>% .[1,]
    
    if(length(results$article_text) == 0){results$article_text   <- NA}
    if(is.na(results$article_source) | (length(results$article_source)==0)){ results$article_source <- "reuters" }
    
  },silent = TRUE)
  
  return(results)
  
}

