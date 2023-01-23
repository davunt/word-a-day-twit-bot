import tweepy
import requests
import json
import os


rapidAPI_key = os.environ.get('rapidAPI_key')
rapidAPI_host = os.environ.get('rapidAPI_host')
tw_consumer_key = os.environ.get('tw_consumer_key')
tw_consumer_secret = os.environ.get('tw_consumer_secret')
tw_access_token = os.environ.get('tw_access_token')
tw_access_token_secret = os.environ.get('tw_access_token_secret')


def parseWordResults(results):
  definition = ''
  examples = ''
  partOfSpeech = ''

  for details in results:
    if 'definition' in details and 'examples' in details and 'partOfSpeech' in details:
        definition = details['definition']
        examples = details['examples']
        partOfSpeech = details['partOfSpeech']
        break
  return definition, examples, partOfSpeech

def composeTweet(word, partOfSpeech, definition, examples):
  client = tweepy.Client(
    consumer_key = tw_consumer_key,
    consumer_secret = tw_consumer_secret,
    access_token = tw_access_token,
    access_token_secret = tw_access_token_secret
  )

  tweetText = f"{word} ({partOfSpeech}): {definition}\r\n\r\nexample: {examples[0]}"
  print(tweetText)

  response = client.create_tweet(text=tweetText)

  print(response)



def getNewWord():
  url = "https://wordsapiv1.p.rapidapi.com/words/"

  querystring = { "random" : "true", "hasDetails": "definitions", "hasDetails": "examples" }

  headers = {
    "X-RapidAPI-Key": rapidAPI_key,
    "X-RapidAPI-Host": rapidAPI_host
  }

  response = requests.request("GET", url, headers=headers, params=querystring)
  parsedResponse = json.loads(response.text)
  print(parsedResponse)

  word = parsedResponse['word']
  results = parsedResponse['results']

  definition, examples, partOfSpeech = parseWordResults(results)  

  composeTweet(word, partOfSpeech, definition, examples)


def handler(event, context):
    print(event)

    getNewWord()

    return {
        'statusCode': 200,
    }
