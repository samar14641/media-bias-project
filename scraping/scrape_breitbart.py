from urllib.request import urlopen
from bs4 import BeautifulSoup
import pandas as pd
import time
import pdb
from datetime import datetime

# print(dir(urllib))
collection_date = str(datetime.today().date())

links = {"source": [], "link": [], "lastmod": [], "filed_under": [], "collection_date": [], "article_date": [],
"article_headline": [], "article_author": [], "article_source": [], "article_tag": [], "article_text": [], "http_status_code": []}

for date in pd.date_range("1/1/2019", pd.datetime.today()):
	print(date)
	map_link = "https://www.breitbart.com/politics/{}/{}/{}/".format(date.year, date.month, date.day)
	page = urlopen(map_link)

	soup = BeautifulSoup(page, 'html.parser')

	divs = soup.find_all("div", attrs={"class": "tC"})
	for div in divs:
		try:
			article_link = div.find('a').attrs['href']
			article = urlopen("https://www.breitbart.com/politics/" + article_link)
			links['source'].append(map_link)
			links['link'].append(article_link)
			links["lastmod"].append(date)
			links["filed_under"].append("politics")
			links["collection_date"].append(collection_date)
			article_soup = BeautifulSoup(article, 'html.parser')
			links["article_date"].append(article_soup.find_all("time")[0].text)
			links["article_headline"].append(article_soup.find_all("h1")[0].text)
			links["article_author"].append(article_soup.find("address").text)
			links["article_source"].append("Breitbart")
			links["article_tag"].append(",".join([l.text for l in article_soup.find_all("p", {"class": 'rmoreabt'})[0].find_all("a")]))
			links["article_text"].append(article_soup.find_all("div", {"class": "entry-content"})[0].text)
			links["http_status_code"].append(article.getcode())
		except Exception as e:
			print(e)

	# time.sleep(0.1)


pd.DataFrame(links).to_csv("Breitbart_Links.csv")
