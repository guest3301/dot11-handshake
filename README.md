# dot11-handshake

A script that attempts to capture a WPA2 four‑way handshake and converts it to hashcat (mode 22000) format.
This script would run perfectly on debian-based linux systems running on newer linux kernel versions (=> 6).
Because running the same sets of commands for me again and again was kinda annoying so I wrote this tiny script. I'm not diving into technicalities so feel free to explore the code inside `script.sh`.


If you are curious and want to dive deeper into WPA2 you use [this](https://networklessons.com/wireless/wpa-and-wpa2-4-way-handshake) as reference.


## Installation

```bash
curl https://raw.githubusercontent.com/guest3301/dot11-handshake/refs/heads/main/script.sh -o script
chmod +x script
./script
```

## Usage

1. Run the script (as root):
   ```bash
   sudo ./script
   ```

2. Revert the Wi-Fi adapter back to managed mode using:

   ```bash
   sudo ./script stop
   ```

2. Crack the captured handshake with **hashcat** using wordlist:
   ```bash
   hashcat -m 22000 -a 0 -w 4 -O /tmp/ws_handshake/capture.hc22000 <wordlist>
   ```
   Example:
   ```bash
   hashcat -m 22000 -a 0 -w 4 -O /tmp/ws_handshake/capture.hc22000 /usr/share/wordlists/rockyou.txt
   ```

---

### DISCLAIMER

This script is for **educational and demonstration purposes only**.  
I am not, in any way, encouraging you to use it against networks you don’t own or have explicit permission to test.  
**YOU** chose to run these commands.  
If you break the law, damage your hardware, soft‑brick a router, get your Wi‑Fi banned, or accidentally cause your neighbour’s cat to disconnect from the internet, and if you point your finger at me, I will laugh at you, and make fun of you for not reading this disclaimer, I will **NOT** be liable for the things you did.  
