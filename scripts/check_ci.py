import urllib.request
import json
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8')

def check_ci():
    proc = subprocess.Popen(['git', 'credential', 'fill'], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    out, _ = proc.communicate('protocol=https\nhost=github.com\n')
    token = ''
    for line in out.splitlines():
        if line.startswith('password='):
            token = line.split('=', 1)[1]

    req = urllib.request.Request('https://api.github.com/repos/itssagarK/edito/actions/runs?per_page=3', headers={
        'Authorization': f'token {token}',
        'User-Agent': 'Edito-Agent',
        'Accept': 'application/vnd.github.v3+json'
    })
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read().decode())
            for r in data.get('workflow_runs', []):
                head_branch = r.get('head_branch', '')
                head_sha = r.get('head_sha', '')[:7]
                run_id = r['id']
                print(f"Run #{r['run_number']} (ID {run_id}): {r['name']} ({r['event']}) [{head_branch}@{head_sha}] -> Status: {r['status']}, Conclusion: {r['conclusion']}")
                
                # Check jobs for latest run
                if r['status'] == 'in_progress' or r['conclusion'] == 'failure':
                    j_req = urllib.request.Request(f'https://api.github.com/repos/itssagarK/edito/actions/runs/{run_id}/jobs', headers={
                        'Authorization': f'token {token}',
                        'User-Agent': 'Edito-Agent',
                        'Accept': 'application/vnd.github.v3+json'
                    })
                    with urllib.request.urlopen(j_req) as j_resp:
                        j_data = json.loads(j_resp.read().decode())
                        for j in j_data.get('jobs', []):
                            print(f"   Job: {j['name']} -> {j['status']}, {j['conclusion']}")
                            for s in j.get('steps', []):
                                if s['status'] != 'completed' or s['conclusion'] == 'failure':
                                    print(f"     Step: {s['name']} -> {s['status']}, {s['conclusion']}")
    except Exception as e:
        print(f"Error checking CI: {e}")

if __name__ == '__main__':
    check_ci()
