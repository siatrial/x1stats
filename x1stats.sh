#!/usr/bin/env bash

tput civis  # Hide cursor

system_stats_monitor() {
    clear

    # Initialize variables
    declare -A prev_total prev_idle
    frame=0
    last_slot=0
    last_tx_count=0
    last_time=$(date +%s)

    # Get initial CPU stats
    for i in $(seq 0 $(($(nproc)-1))); do
        read -r cpu user nice system idle rest <<< "$(grep "cpu$i" /proc/stat)"
        prev_total["$i"]=$((user + nice + system + idle))
        prev_idle["$i"]=$idle
    done

    # Get network interface
    interface=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
    [ -z "$interface" ] && interface="lo"

    rx_old=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo 0)
    tx_old=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo 0)

    while true; do
        tput cup 0 0  # Reset cursor position

        # ──────────────────────────────────────────────────────────
        uptime_info=$(uptime -p | cut -d' ' -f2-)
        echo -e "=============================================================="
        printf " X1 Stats         Uptime: %-14s \n" "${uptime_info:0:14}"
        echo -e "=============================================================="

        # ──────────────────────────────────────────────────────────
        rx_new=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_new=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo 0)
        rx_speed=$(( (rx_new - rx_old) * 2 ))
        tx_speed=$(( (tx_new - tx_old) * 2 ))
        rx_old=$rx_new
        tx_old=$tx_new
        
        if command -v numfmt &>/dev/null; then
            rx=$(numfmt --to=iec-i --suffix=B/s $rx_speed 2>/dev/null || echo "${rx_speed}B/s")
            tx=$(numfmt --to=iec-i --suffix=B/s $tx_speed 2>/dev/null || echo "${tx_speed}B/s")
        else
            rx="${rx_speed}B/s"
            tx="${tx_speed}B/s"
        fi

        printf " Network    In: %-8s   Out: %-8s \n" "$rx" "$tx"
        echo -e "=============================================================="

        # ──────────────────────────────────────────────────────────
        read -r total used _ <<< "$(free -b | awk '/Mem:/ {print $2,$3}')"
        mem_percent=$(( total > 0 ? (used * 100) / total : 0 ))

        if command -v bc &>/dev/null; then
            used_gb=$(echo "scale=1; $used/1073741824" | bc 2>/dev/null || echo "N/A")
            total_gb=$(echo "scale=1; $total/1073741824" | bc 2>/dev/null || echo "N/A")
        else
            used_gb="$((used / 1073741824))"
            total_gb="$((total / 1073741824))"
        fi

        # Memory Bar (|.., ||., |||)
        mem_bar="|.."
        ((mem_percent >= 3))  && mem_bar="..."
        ((mem_percent >= 5))  && mem_bar="|.."
        ((mem_percent >= 40)) && mem_bar="||."
        ((mem_percent >= 70)) && mem_bar="|||"        

        printf " Mem: %-3s %3d%% (%4.1fG/%4.1fG) \n" "$mem_bar" "$mem_percent" "$used_gb" "$total_gb"
        echo -e "=============================================================="

        # ──────────────────────────────────────────────────────────
        if command -v tachyon-validator &>/dev/null; then
            validator_data=$(timeout 3 tachyon-validator --ledger "$HOME/x1/ledger" monitor 2>/dev/null)
            current_slot=$(echo "$validator_data" | grep -o "Processed Slot: [0-9]*" | awk '{print $3}' | head -n 1)
            tx_count=$(echo "$validator_data" | grep -o "Transactions: [0-9]*" | awk '{print $2}' | head -n 1)

            if [[ -n "$current_slot" && "$current_slot" -gt 0 && -n "$tx_count" ]]; then
                current_time=$(date +%s)
                time_diff=$((current_time - last_time))
                slot_diff=$((current_slot - last_slot))
                tx_diff=$((tx_count - last_tx_count))

                if ((time_diff > 0)); then
                    blocks_per_sec=$(echo "scale=2; $slot_diff / ($time_diff + 1)" | bc 2>/dev/null || echo "N/A")
                    tps=$(echo "scale=2; $tx_diff / ($time_diff + 1)" | bc 2>/dev/null || echo "N/A")
                else
                    blocks_per_sec=0
                    tps=0
                fi

                last_slot=$current_slot
                last_time=$current_time
                last_tx_count=$tx_count

                printf " Blocks/sec: \e[32m%-6s\e[0m (Slot: %s)\n" "$blocks_per_sec" "$current_slot"
                printf " TPS: \e[32m%-6s\e[0m \n" "$tps"
            else
                echo -e " Blocks/sec: \e[90mNo data available\e[0m"
                echo -e " TPS: \e[90mNo data available\e[0m"
            fi
            echo -e "=============================================================="
        fi

        # ──────────────────────────────────────────────────────────
        echo -e "\n CPU Cores Utilization:"

        num_cpus=$(nproc)
        mid=$((num_cpus / 2))

        for i in $(seq 0 $((mid - 1))); do
            read -r cpu user nice system idle rest <<< "$(grep "cpu$i" /proc/stat)"
            curr_total=$((user + nice + system + idle))
            curr_idle=$idle
            delta_total=$((curr_total - prev_total["$i"]))
            delta_idle=$((curr_idle - prev_idle["$i"]))
            usage=$(( delta_total > 0 ? (100 * (delta_total - delta_idle)) / delta_total : 0 ))
            prev_total["$i"]=$curr_total
            prev_idle["$i"]=$idle

            cpu_bar="|.."
            ((usage >= 3))  && cpu_bar="..."
            ((usage >= 20)) && cpu_bar="|.."
            ((usage >= 40)) && cpu_bar="||."
            ((usage >= 85)) && cpu_bar="|||"
            
            j=$((i + mid))
            read -r cpu2 user2 nice2 system2 idle2 rest2 <<< "$(grep "cpu$j" /proc/stat)"
            curr_total2=$((user2 + nice2 + system2 + idle2))
            curr_idle2=$idle2
            delta_total2=$((curr_total2 - prev_total["$j"]))
            delta_idle2=$((curr_idle2 - prev_idle["$j"]))
            usage2=$(( delta_total2 > 0 ? (100 * (delta_total2 - delta_idle2)) / delta_total2 : 0 ))
            prev_total["$j"]=$curr_total2
            prev_idle["$j"]=$idle2

            cpu_bar2="|.."
            ((usage2 >= 3))  && cpu_bar2="..."
            ((usage2 >= 20)) && cpu_bar2="|.."
            ((usage2 >= 40)) && cpu_bar2="||."
            ((usage2 >= 85)) && cpu_bar2="|||"
            
            printf " Core %02d: %-3s %3d%%   Core %02d: %-3s %3d%%\n" "$i" "$cpu_bar" "$usage" "$j" "$cpu_bar2" "$usage2"
        done

        echo -e "=============================================================="

        sleep 1
    done
}

system_stats_monitor
