import urllib.request
import subprocess
import sys
import json

sys.stdout.reconfigure(encoding='utf-8')

def get_all_errors():
    proc = subprocess.Popen(['git', 'credential', 'fill'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    out, _ = proc.communicate('protocol=https\nhost=github.com\n')
    token = ''
    for line in out.splitlines():
        if line.startswith('password='):
            token = line.split('=', 1)[1]

    run_id = sys.argv[1] if len(sys.argv) > 1 else '35439953060'
    cmd = [
        'curl.exe', '-s',
        '-H', f'Authorization: token {token}',
        '-H', 'Accept: application/vnd.github.v3+json',
        f'https://api.github.com/repos/itssagarK/edito/actions/runs/{run_id}/jobs'
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    jobs = json.loads(res.stdout).get('jobs', [])
    job_id = jobs[0]['id']

    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            return None

    opener = urllib.request.build_opener(NoRedirect)
    req = urllib.request.Request(
        f'https://api.github.com/repos/itssagarK/edito/actions/jobs/{job_id}/logs',
        headers={'Authorization': f'token {token}', 'User-Agent': 'Edito'}
    )
    try:
        opener.open(req)
        s3_url = None
    except urllib.error.HTTPError as e:
        if e.code in (302, 301, 307):
            s3_url = e.headers['Location']
        else:
            raise

    if s3_url:
        with urllib.request.urlopen(s3_url) as resp:
            text = resp.read().decode('utf-8', errors='ignore')
            lines = text.splitlines()
            print("--- ALL ERROR OCCURRENCES ---")
            for i, line in enumerate(lines):
                if 'Error:' in line or 'error:' in line:
                    print(f"L{i}: {line}")

if __name__ == '__main__':
    get_all_errors()
