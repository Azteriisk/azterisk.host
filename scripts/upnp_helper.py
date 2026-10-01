#!/usr/bin/env python3
import sys
import subprocess
import json
import socket
import re
import os

CONFIG_PATH = os.path.join(os.path.dirname(__file__), '..', 'config.json')

def get_local_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(('10.255.255.255', 1))
        ip = s.getsockname()[0]
    except Exception:
        ip = '127.0.0.1'
    finally:
        s.close()
    return ip

def get_external_ip():
    try:
        result = subprocess.run(['upnpc', '-s'], capture_output=True, text=True, timeout=5)
        match = re.search(r'ExternalIPAddress = (\d+\.\d+\.\d+\.\d+)', result.stdout)
        if match:
            return match.group(1)
    except Exception:
        pass
    return None

def run_cmd(args):
    try:
        res = subprocess.run(args, capture_output=True, text=True, timeout=10)
        return res.returncode == 0, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return False, "", str(e)

def load_config():
    try:
        with open(CONFIG_PATH, 'r') as f:
            items = json.load(f)
        
        # Check status for each
        for item in items:
            item['app_running'] = False
            if item.get('manager') == 'docker' and item.get('target'):
                ok, out, _ = run_cmd(['docker', 'inspect', '-f', '{{.State.Running}}', item['target']])
                if ok and out == 'true':
                    item['app_running'] = True
            elif item.get('manager') == 'systemd' and item.get('target'):
                ok, _, _ = run_cmd(['systemctl', '--user', 'is-active', '--quiet', item['target']])
                if ok:
                    item['app_running'] = True
                else:
                    ok2, _, _ = run_cmd(['systemctl', 'is-active', '--quiet', item['target']])
                    if ok2: item['app_running'] = True
        return items
    except Exception:
        return []

def manage_app(manager, target, action):
    if manager == 'docker':
        ok, out, err = run_cmd(['docker', action, target])
        return {"success": ok, "error": err if not ok else ""}
    elif manager == 'systemd':
        # Try user first, then system
        ok, out, err = run_cmd(['systemctl', '--user', action, target])
        if not ok and 'Failed to connect' not in err:
            ok, out, err = run_cmd(['sudo', '-n', 'systemctl', action, target])
        return {"success": ok, "error": err if not ok else ""}
    return {"success": False, "error": "Unknown manager"}

def main():
    if len(sys.argv) < 2:
        sys.exit(1)
        
    cmd = sys.argv[1]
    if cmd == "status":
        print(json.dumps({
            "success": True, 
            "external_ip": get_external_ip(),
            "items": load_config()
        }))
    elif cmd == "add":
        # UPnP add
        local_ip = get_local_ip()
        ok, out, err = run_cmd(['upnpc', '-a', local_ip, sys.argv[2], sys.argv[2], sys.argv[3].upper()])
        if ok or "is redirected to internal" in out:
            print(json.dumps({"success": True, "ip": get_external_ip()}))
        else:
            print(json.dumps({"success": False, "error": out or err}))
    elif cmd == "remove":
        # UPnP remove
        ok, out, err = run_cmd(['upnpc', '-d', sys.argv[2], sys.argv[3].upper()])
        print(json.dumps({"success": True}))
    elif cmd == "app":
        action = sys.argv[2]
        manager = sys.argv[3]
        target = sys.argv[4]
        print(json.dumps(manage_app(manager, target, action)))

if __name__ == "__main__":
    main()
