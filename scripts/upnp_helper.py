#!/usr/bin/env python3
import sys
import subprocess
import json
import socket
import re

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

def add_forward(port, protocol):
    local_ip = get_local_ip()
    if local_ip == '127.0.0.1':
        return {"success": False, "error": "No network connection"}
    
    # Run upnpc -a <local_ip> <port> <port> <protocol>
    try:
        result = subprocess.run(['upnpc', '-a', local_ip, str(port), str(port), protocol.upper()], capture_output=True, text=True, timeout=10)
        if "TCP is redirected to internal" in result.stdout or "UDP is redirected to internal" in result.stdout or "is redirected to internal" in result.stdout:
            ext_ip = get_external_ip()
            return {"success": True, "ip": ext_ip, "port": port, "protocol": protocol.upper()}
        else:
            return {"success": False, "error": result.stdout.strip() or result.stderr.strip() or "Failed to map port"}
    except Exception as e:
        return {"success": False, "error": str(e)}

def remove_forward(port, protocol):
    try:
        result = subprocess.run(['upnpc', '-d', str(port), protocol.upper()], capture_output=True, text=True, timeout=5)
        return {"success": True}
    except Exception as e:
        return {"success": False, "error": str(e)}

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"success": False, "error": "Missing command"}))
        sys.exit(1)
        
    cmd = sys.argv[1]
    if cmd == "add":
        if len(sys.argv) < 4:
            print(json.dumps({"success": False, "error": "Missing port or protocol"}))
            sys.exit(1)
        print(json.dumps(add_forward(sys.argv[2], sys.argv[3])))
    elif cmd == "remove":
        if len(sys.argv) < 4:
            print(json.dumps({"success": False, "error": "Missing port or protocol"}))
            sys.exit(1)
        print(json.dumps(remove_forward(sys.argv[2], sys.argv[3])))
    elif cmd == "status":
        ip = get_external_ip()
        print(json.dumps({"success": True, "external_ip": ip}))
    else:
        print(json.dumps({"success": False, "error": "Unknown command"}))
        sys.exit(1)

if __name__ == "__main__":
    main()
