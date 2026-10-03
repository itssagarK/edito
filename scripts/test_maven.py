import urllib.request, json

url = 'https://search.maven.org/solrsearch/select?q=ffmpeg-kit-full-gpl&rows=5&wt=json'
req = urllib.request.Request(url, headers={'User-Agent': 'test'})
data = json.loads(urllib.request.urlopen(req).read().decode('utf-8'))
for doc in data['response']['docs']:
    print(doc)
