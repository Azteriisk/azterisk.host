#!/usr/bin/env python3
import sys
import subprocess
import json

def run_cmd(args):
    try:
        res = subprocess.run(args, capture_output=True, text=True, timeout=5)
        return res.stdout.strip(), res.stderr.strip(), res.returncode
    except Exception as e:
        return "", str(e), 1

def list_containers():
    out, err, code = run_cmd(['docker', 'ps', '-a', '--format', '{{.ID}}|{{.Names}}|{{.State}}|{{.Ports}}'])
    if code != 0:
        return {"success": False, "error": err or "Docker not running"}
    
    containers = []
    for line in out.split('\n'):
        if not line: continue
        parts = line.split('|')
        if len(parts) >= 4:
            cid, name, state, ports = parts[0], parts[1], parts[2], parts[3]
            containers.append({
                "id": cid,
                "name": name,
                "state": state,
                "ports": ports
            })
    return {"success": True, "containers": containers}

def manage_container(action, cid):
    out, err, code = run_cmd(['docker', action, cid])
    if code != 0:
        return {"success": False, "error": err}
    return {"success": True}

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    
    cmd = sys.argv[1]
    if cmd == "list":
        print(json.dumps(list_containers()))
    elif cmd in ["start", "stop", "restart"]:
        if len(sys.argv) < 3:
            sys.exit(1)
        print(json.dumps(manage_container(cmd, sys.argv[2])))
