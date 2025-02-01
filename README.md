X1Stats is a real-time monitoring script designed for X1 Validators running on Linux systems. 
It provides live updates on system resources, network traffic, and validator performance, 
helping operators track system health efficiently.

Key Features
✔️ Real-time CPU Usage per core with dynamic indicators
✔️ Memory & Swap Monitoring with graphical representation
✔️ Network Speed Display (incoming & outgoing)
✔️ X1 Validator Performance Tracking (blocks processed per second)
✔️ Multi-Core Utilization Graph with color-coded thresholds
✔️ High Compatibility across various Linux distributions
✔️ Auto-Refresh & Optimized for SSH/Tmux Usage

Install dependencies
sudo apt update && sudo apt install bc coreutils curl iproute2 -y

Clone the GitHub repository

git clone https://github.com/siatrial/x1stats.git

cd x1stats

Make the script executable

chmod +x x1stats.sh

Run the script

./x1stats.sh


📊 Metrics Displayed
🔹 System Stats
Uptime
Network Traffic (Download/Upload speeds)
Memory Usage (Graphical bar + percentage)
🔹 Validator Performance
Blocks Processed Per Second
Latest Processed Slot Number
🔹 CPU Utilization
Each core’s usage (%)
3-bar graphical representation per core
No bars: 0-5% load
▇ (Low load): 5-30%
▇▇ (Medium load): 30-70%
▇▇▇ (High load): 70-100%
Thresholds
Green (Safe usage)
Yellow (Medium load)
Red (High load)

<img width="465" alt="Screenshot 2025-02-01 at 15 27 53" src="https://github.com/user-attachments/assets/fca739f8-ff10-476b-9380-8edcc265d959" />
