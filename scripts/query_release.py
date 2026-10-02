import subprocess
import urllib.request
import json
import os
import sys

def get_token():
    proc = subprocess.Popen(['git', 'credential', 'fill'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    out, _ = proc.communicate('protocol=https\nhost=github.com\n')
    for line in out.splitlines():
        if line.startswith('password='):
            return line.split('=', 1)[1]
    return ''

def main():
    token = get_token()
    if not token:
        print("Failed to get GitHub token.")
        return

    req = urllib.request.Request('https://api.github.com/repos/itssagarK/edito/releases/tags/v1.0.70', headers={
        'Authorization': f'token {token}',
        'User-Agent': 'Edito-Agent',
        'Accept': 'application/vnd.github.v3+json'
    })
    
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())
            print(f"Release ID: {data.get('id')}")
            print(f"Release Name: {data.get('name')}")
            print(f"Upload URL: {data.get('upload_url')}")
            print("Existing Assets:")
            for a in data.get('assets', []):
                print(f"  - {a.get('name')} (size: {a.get('size')} bytes, id: {a.get('id')}) -> {a.get('browser_download_url')}")
    except Exception as e:
        print(f"Error fetching release: {e}")

if __name__ == '__main__':
    main()
