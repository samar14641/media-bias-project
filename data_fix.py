import pandas as pd
from bs4 import BeautifulSoup
from urllib.request import urlopen
import time
import re
i = 0

data = pd.read_csv("ArticleData.csv")
pattern = re.compile('.*paragraph.*')

def fix_article_text(row, retries=0):
	if retries == 5:
		return row
	try:
		is_cnn = row['news_site'] == 'cnn'

		if is_cnn:
			global i
			i += 1
			
			soup = BeautifulSoup(urlopen(row['link']), 'html.parser')
			soup.script.decompose()
			a_text = soup.find('section', {'data-zone-label': 'bodyText'})
			text = '\n'.join([x.text for x in a_text.find_all('div', {'class': pattern})])
			row['article_text'] = text
			if i % 10 == 0:
				print(i)
		return row
	except:
		time.sleep(5)
		retries += 1
		print("retry {} on link: {}".format(retries, row['link']))
		return fix_article_text(row, retries)

data.apply(fix_article_text, axis=1)
data.to_csv("ArticleData2.csv")