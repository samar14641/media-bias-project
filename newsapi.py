# Using the News API

from dotenv import load_dotenv  # pip install python-dotenv
import requests
import os
import math

load_dotenv()
NEWS_API_KEY = os.getenv('NEWS_API_KEY')

source = 'cnn'  # News sources: 
q = 'election'  # Keyword in title/body
page = 1
URL = 'https://newsapi.org/v2/everything?sources=' + source + '&q=' + q + '&pageSize=100&page=' + str(page) + '&apiKey=' + NEWS_API_KEY


response = requests.get(URL)
data = response.json()


links = {'source': [], 'link': [], 'date': []}


if data['status'] == 'error':
    print('!ERROR!')
    print(data['message'])
else:
    for i in range(len(data['articles'])):
        links['link'].append(data['articles'][i]['url'])
        links['date'].append(data['articles'][i]['publishedAt'])
        links['source'].append(source)

# DEV ACCOUNTS ARE LIMITED TO 100 RESULTS
# if data['totalResults'] > 100:
#     while page < math.ceil(data['totalResults'] / 100):
#         page += 1
#         URL = 'https://newsapi.org/v2/everything?sources=' + source + '&q=' + q + '&pageSize=100&page=' + str(page) + '&apiKey=' + NEWS_API_KEY
#         response = requests.get(URL)
#         data = response.json()
#         if data['status'] == 'error':
#             print('!ERROR!')
#             print(data['message'])
#         else:
#             for i in range(len(data['articles'])):
#                 links['link'].append(data['articles'][i]['url'])
#                 links['date'].append(data['articles'][i]['publishedAt'])
#                 links['source'].append(source)


print(links['link'])