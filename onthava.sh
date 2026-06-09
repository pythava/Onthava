#!/bin/bash

#default Level
VERBOSITY=2

while getopts "v:" opt; do
    case $opt in
        v)
            if [[ "$OPTARG" == "1" || "$OPTARG" == "2" || "$OPTARG" == "3" ]]; then
                VERBOSITY=$OPTARG
            else
                echo "[-] Invalid level. Use -v 1, -v 2, or -v 3."
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [-v 1 | -v 2 | -v 3]"
            exit 1
            ;;
    esac
done

BASE_FILTER="onthava|kworker|ksoftirqd|rcu_|migration"
if [ "$VERBOSITY" -eq 1 ]; then
    FILTER_REGEX="${BASE_FILTER}|vpnip\.sh|systemd-userwork|sessionclean|defunct|systemd"
elif [ "$VERBOSITY" -eq 2 ]; then
    FILTER_REGEX="${BASE_FILTER}|systemd-userwork|systemd"
else
    FILTER_REGEX="${BASE_FILTER}"
fi

echo "onthava v.0.5 [Polling Stable]"
cat << 'EOF'
 ▓█████▄  ███▄    █ ▄▄▄█████▓ ██   ██  ▄▄▄       ██▒   █▓  ▄▄▄      
 ▒██▒  ██▒██ ▀█   █ ▓  ██▒ ▓▒ ██   ██ ▒████▄    ▓██░   █▒ ▒████▄    
 ▒██░  ██▒██ ▀█ ██▒▒ ▓██░ ▒░  ███████▒▒██  ▀█▄   ▓██  █▒ ▒██  ▀█▄   
 ▒██   ██░██▒  ▐▌██▒ ░ ▓██▓ ░  ██   ██ ░██▄▄▄▄██   ▒██ █░  ░██▄▄▄▄██ 
  ██████ ░██░   ▓██░   ▒██▒ ░  ██   ██  ▓█   ▓██▒   ▒▀█░    ▓█   ▓██▒
EOF
echo ""
echo "[+] Verbosity level : $VERBOSITY"
echo "[+] Initializing process monitor (polling /proc)..."
echo "[+] Press Ctrl+C to stop."
echo ""

declare -A SEEN_PIDS
for pid_dir in /proc/[0-9]*; do
    pid="${pid_dir##*/}"
    SEEN_PIDS["$pid"]=1
done

while true; do
    for pid_dir in /proc/[0-9]*; do
        pid="${pid_dir##*/}"

        [[ -n "${SEEN_PIDS[$pid]}" ]] && continue
        SEEN_PIDS["$pid"]=1

        [ -f "/proc/$pid/cmdline" ] || continue

        args=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null)
        args="${args%% }" 

        if [[ -z "$args" || "$args" =~ ($FILTER_REGEX) ]]; then
            continue
        fi

        user=$(ps -o user= -p "$pid" 2>/dev/null | tr -d ' ')
        [ -z "$user" ] && user="unknown"

        current_time=$(date +"[%H:%M:%S]")
        printf "%s \e[1;32m%-12s\e[0m \e[1;36m%-7s\e[0m %s\n" \
            "$current_time" "$user" "$pid" "$args"
    done

    cleanup_counter=$(( (cleanup_counter + 1) % 100 ))
    if [ "$cleanup_counter" -eq 0 ]; then
        for pid in "${!SEEN_PIDS[@]}"; do
            [ -d "/proc/$pid" ] || unset "SEEN_PIDS[$pid]"
        done
    fi

    sleep 0.1
done
