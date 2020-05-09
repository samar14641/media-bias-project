# DS5110-Project

Process/File Structure: https://www.lucidchart.com/invitations/accept/606d0efe-c092-4a3f-90f3-73e30101b755

Check filterREADME.txt for filters info.

#### Using news_scraper

* Navigate to directory the news_scraper_main.R file is contained in. list.dirs("site_utilies") should find the site_utilies folder.
* Run the scraper with options you choose, by default it will find everything for the last three months. In the the scraper_main file there is a test version.

##### Adding new sites to the scraper

* Follow the naming format (i.e. fivethirty_utils.R, fivethirtyeight_sitemap, etc.). This is so the scraper can detect the functions.
* Each function takes one step in the process, assuming we can visit a sitemap to get article links and then follow the links to the news articles

*Required Functions for a new site*

* *_sitemap: Where to start. Generally where to find archives for the last_x_months. i.e. https://fivethirtyeight.com/sitemap-index-1.xml
  - Input: last_x_months as requested in the main function
  - Output: A *list* of archive links to search in the next function.
* *_find_links: Given a list of site archives (each monthly more or less), visit each link and find every article. i.e. https://fivethirtyeight.com/sitemap-1.xml + however many more are necessary to cover the right timeframe
  - Input: *One* archive link from the *_sitemap function which is a url string.
  - Output:Return a named list/data.table/dataframe with columns 2-6 (in order). The source column will be taken care of by the main function.
* *_article: Essentially given a link to a news article from that site, scrape it and return a list of results
  - Input: One link to a news article from the site.
  - Output:Return a named list/data.table/dataframe with columns 7-12 (in order).

#### Preliminary Data Columns

  1. Source (considering renaming this to "archive_link" for clarity):
  This provides a link to the archive/sitemap page the article link was collected from. (i.e. https://fivethirtyeight.com/sitemap-1.xml)

  2. link (considering renaming this to "article_link" for clarity):
  Provides a link to the article (i.e. https://fivethirtyeight.com/features/significant-digits-for-thursday-oct-3-2019/)

  3. lastmod:
  Date the article was last modified on. Largely being used as a quickly accessible proxy for article publication date
  4. changefreq
  How often the article was modified (usually "never")
  5. priority:
  Article priority per sitemap (may be dropped as unnecessary)
  6. filed_under:
  Best category we can get from the link alone. i.e. for https://www.foxnews.com/science/wreck-japanese-aircraft-carrier-discovered-battle-of-midway the category is "science." Useful as a preliminary filter to decide which articles it is worth getting more detailed information on. Varies by site and might not always be available (i.e. all FiveThirtyEight articles are "features" but nothing more is immeadiately available)

**Important: All following columns ("article_*") are collected by visiting the article link directly. Unlike the previous columns they are not available until the article link has been visited. Also they by necessity vary a bit by site, generally it's the best match available.**

  7. article_date: Date article was published on as available in whatever format is in the article.
  8. article_headline: Article headline.
  9. article_author: author(s)
  9. article_source: The source of the article. Usually the news site your scraping on but sometimes not, i.e. Fox will publish articles from AP.
  10. article_tag: A tag or list of topics the article is associated with, per the site. Generally much more detailed than what may be available under "filed_under."
  11. article_text: The main target of the scraper, the actual news article text in full as a string.
  12. http_status_code: A http status code that was returned when the request was sent to the article link. Used for debugging. i.e. 200 = Good response, 404 = bad link, 403 = Forbidden, ip address might have been blocked
  13. collection_date: Date and time the data was collected (i.e. when we ran the code)
