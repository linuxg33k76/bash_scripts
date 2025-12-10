#!/usr/bin/env python3
import subprocess
import time
import os
import shutil
import pprint

KNOWN_FILE = "/tmp/known_outbound_py.txt"
HOSTNAME = subprocess.getoutput("hostname")

def get_connections():
    """Run ss -tupn and return a set of lines."""
    try:
        # Check if ss is available (it should be as per bash script)
        result = subprocess.run(["ss", "-tupn"], capture_output=True, text=True, check=True)
        lines = result.stdout.strip().split('\n')
        # We process lines as strict strings for comparison, just like comm in bash
        # Filtering out empty lines if any
        return set(line for line in lines if line.strip())
    except subprocess.CalledProcessError as e:
        print(f"Error running ss: {e}")
        return set()

def load_known_connections():
    """Load known connections from file."""
    if not os.path.exists(KNOWN_FILE):
        return set()
    try:
        with open(KNOWN_FILE, 'r') as f:
            return set(line.strip() for line in f)
    except Exception as e:
        print(f"Error reading {KNOWN_FILE}: {e}")
        return set()

def save_known_connections(connections):
    """Save current connections to file."""
    try:
        with open(KNOWN_FILE, 'w') as f:
            for line in connections:
                f.write(line + '\n')
    except Exception as e:
        print(f"Error writing {KNOWN_FILE}: {e}")

def get_whois_info(ip):
    """Run whois and grep for specific fields."""
    try:
        # Using subprocess to pipe whois output to grep logic or doing it in python
        # Doing it in Python is cleaner
        result = subprocess.run(["whois", ip], capture_output=True, text=True)
        output = result.stdout
        
        info = []
        for line in output.split('\n'):
            if any(key in line for key in ["OrgName:", "City:", "Country:", "OrgAbuse"]):
                info.append(line.strip())
        return "\n".join(info)
    except Exception as e:
        return f"Whois lookup failed: {e}"

def notify_hyprland(message):
    """Send notification via hyprctl."""
    # The plan included this, so we add it. 
    # Bash: hyprctl notify -1 10000 "rgb(ff0000)" "[ALERT] ..."
    try:
        if shutil.which("hyprctl"):
            subprocess.run([
                "hyprctl", "notify", "-1", "10000", "rgb(ff0000)", message
            ], check=False)
    except Exception as e:
        print(f"Failed to send Hyprland notification: {e}")

def main():
    # Initial run to populate known file if empty, similar to bash script logic
    # Bash script runs 'ss -tupn > $KNOWN' at start.
    current_connections = get_connections()
    save_known_connections(current_connections)
    
    print(f"[WATCHDOG] Started monitoring on {HOSTNAME}...")

    while True:
        try:
            # 1. Get current
            current_connections = get_connections()
            
            # 2. Get known (from previous iteration/file)
            known_connections = load_known_connections()
            
            # 3. Calculate new
            # Bash: comm -13 <(sort known) <(sort current) -> lines in current that are not in known
            new_connections = current_connections - known_connections

            pprint.pprint(new_connections)
            
            if new_connections:
                for line in new_connections:
                    # Skip the header line if it appears as "new" (it shouldn't if it was in known, but safety check)
                    if line.startswith("Netid"):
                        continue

                    # Parse fields matches awk logic:
                    # $1: Type, $5: Source, $6: Dest, $7: User
                    parts = line.split()
                    if len(parts) < 6:
                        continue # Malformed line
                        
                    conn_type = parts[0]
                    source = parts[4] # 0-indexed, so $5 is index 4
                    dest_full = parts[5] # $6 is index 5
                    
                    # User info might be at index 6 ($7)
                    user_info = parts[6] if len(parts) > 6 else "N/A"
                    
                    # Parse IP and Port from Dest
                    # Dest format: IP:Port. Handle ipv6 brackets if necessary but bash script just did cut -d:
                    if ':' in dest_full:
                        dest_ip = dest_full.rsplit(':', 1)[0]
                        dest_port = dest_full.rsplit(':', 1)[1]
                    else:
                        dest_ip = dest_full
                        dest_port = "Unknown"

                    # Construct Alert
                    print(f"\n[ALERT] New outbound connections detected for {HOSTNAME}")
                    print(f"Type: {conn_type}")
                    print(f"Source: {source}")
                    print(f"Outbound Destination: {dest_ip}")
                    print(f"Outbound Port: {dest_port}")
                    print(f"User: {user_info}")
                    
                    # WHOIS lookup
                    whois_data = get_whois_info(dest_ip)
                    print(whois_data)
                    print("*************************************************************************")
                    
                    # Hyprland Notify
                    # notify_msg = f"[ALERT] New Outbound: {dest_ip} ({dest_port})"
                    # notify_hyprland(notify_msg)

            # 4. Update known
            save_known_connections(current_connections)
            
            # 5. Sleep
            time.sleep(20)
            
        except KeyboardInterrupt:
            print("\nStopping watchdog.")
            break
        except Exception as e:
            print(f"An error occurred: {e}")
            time.sleep(20)

if __name__ == "__main__":
    main()
