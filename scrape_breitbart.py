from urllib.request import urlopen
from bs4 import BeautifulSoup
import pandas as pd
import time
import pdb

# print(dir(urllib))

links = {"source": [], "link": [], "date": []}
for date in pd.date_range("1/1/2019", pd.datetime.today()):
	print(date)
	page = urlopen("https://www.breitbart.com/politics/{}/{}/{}/".format(date.year, date.month, date.day))

	soup = BeautifulSoup(page, 'html.parser')

	divs = soup.find_all("div", attrs={"class": "tC"})
	for div in divs:
		links['source'].append("breitbart")
		links['link'].append(div.find('a').attrs['href'])
		links["date"].append(date)
	time.sleep(0.1)


pd.DataFrame(links).to_csv("Breitbart_Links.csv")
