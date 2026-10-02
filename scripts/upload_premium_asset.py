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
        sys.exit(1)

    apk_path = os.path.abspath('edito-premium.apk')
    if not os.path.exists(apk_path):
        print(f"File not found: {apk_path}")
        sys.exit(1)

    file_size = os.path.getsize(apk_path)
    print(f"Target file: {apk_path} ({file_size} bytes)")

    upload_url = "https://uploads.github.com/repos/itssagarK/edito/releases/401825540/assets?name=edito-premium.apk"
    print(f"Uploading to {upload_url} via curl.exe...")

    cmd = [
        'curl.exe',
        '-s', '-S',
        '-X', 'POST',
        '-H', f'Authorization: token {token}',
        '-H', 'Content-Type: application/vnd.android.package-archive',
        '-H', 'User-Agent: Edito-Agent',
        '--data-binary', f'@{apk_path}',
        upload_url
    ]

    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if proc.returncode != 0:
        print(f"Upload failed: {proc.stderr}")
        sys.exit(1)

    try:
        resp_json = json.loads(proc.stdout)
        if 'id' in resp_json:
            print("Successfully uploaded asset!")
            print(f"Asset ID: {resp_json['id']}")
            print(f"Name: {resp_json['name']}")
            print(f"Size: {resp_json['size']}")
            print(f"Download URL: {resp_json['browser_download_url']}")
        else:
            print(f"Upload response: {proc.stdout}")
    except Exception as e:
        print(f"Response: {proc.stdout}")
        print(f"Parse error: {e}")

if __name__ == '__main__':
    main()
