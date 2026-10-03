import urllib.request

repos = [
    'https://repo1.maven.org/maven2',
    'https://dl.google.com/dl/android/maven2',
    'https://jitpack.io',
    'https://oss.sonatype.org/content/repositories/releases',
    'https://oss.sonatype.org/content/repositories/snapshots',
]
artifact = 'com/arthenica/ffmpeg-kit-min-gpl/6.0-2/ffmpeg-kit-min-gpl-6.0-2.aar'
for r in repos:
    url = f"{r}/{artifact}"
    try:
        req = urllib.request.Request(url, method='HEAD')
        resp = urllib.request.urlopen(req)
        print(f"FOUND at {r}! Status: {resp.status}")
    except Exception as e:
        print(f"Not at {r}: {e}")
