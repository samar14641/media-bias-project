from urllib.request import urlopen
from bs4 import BeautifulSoup
import pandas as pd
import time
import pdb
import xml.etree.ElementTree as ET
from datetime import datetime
import re

collection_date = str(datetime.today().date())

# print(dir(urllib))

links = {"source": [], "link": [], "lastmod": [], "filed_under": [], "collection_date": [], "article_date": [],
"article_headline": [], "article_author": [], "article_source": [], "article_tag": [], "article_text": [], "http_status_code": []}

xmlns = {"ns": "http://www.sitemaps.org/schemas/sitemap/0.9"}

sitemap = urlopen("https://www.vox.com/sitemaps")
root = ET.parse(sitemap).getroot()


for sm in root.findall("ns:sitemap", xmlns):
	xml_url = sm.find("ns:loc", xmlns).text
	if xml_url.split("/")[-2] == "2019":
		print(xml_url)
		links_root = ET.parse(urlopen(xml_url)).getroot()
		for url_elm in links_root.findall("ns:url", xmlns):
			try:
				article_link = url_elm.find("ns:loc", xmlns).text
				lastmod = url_elm.find("ns:lastmod", xmlns).text
				article = urlopen(article_link)
				http_code = article.getcode()
				if http_code != 200:
					print(http_code)
					continue
				article_soup = BeautifulSoup(article, 'html.parser')
				article_date = "".join(article_soup.find("time", {"data-ui": "timestamp"}).text.strip().split(",")[0:2])
				article_headline = article_soup.find("h1").text
				article_author = article_soup.find("span", {"class": "c-byline__author-name"}).text
				article_text = article_soup.find("div", {"class": "c-entry-content"}).text
				filed_under = article_link.split("/")[2]
				filed_under = "" if filed_under.isnumeric() else filed_under
				tags = article_soup.find("meta", {"name": "sailthru.tags"}).attrs["content"]
				status_code = article.getcode()
				links['source'].append(xml_url)
				links['link'].append(article_link)
				links["lastmod"].append(lastmod)
				links["filed_under"].append("news")
				links["collection_date"].append(collection_date)
				
				links["article_date"].append(article_date)
				links["article_headline"].append(article_headline)
				links["article_author"].append(article_author)
				links["article_source"].append("Vox")
				links["article_tag"].append(tags)
				links["article_text"].append(article_text)
				links["http_status_code"].append(status_code)
			except Exception as e:
				print(e)
		print(len(links["article_date"]))
		pd.DataFrame(links).to_csv("Vox_Links.csv")
pd.DataFrame(links).to_csv("Vox_Links.csv")