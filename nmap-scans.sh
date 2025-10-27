#!/usr/bin/env bash
# nmap-two-stage.sh
# - First scan:  sudo nmap -p- -Pn <target> -oG <file>    (grepable)
# - Second scan: sudo nmap -p<ports> -Pn -sC -sV <target> -oN <file>  (human)
# Behavior:
#  - Two files total (one per scan)
#  - nmap runs attached to terminal (press Enter during scans for live status)
#  - Script prints a safe color summary between scans (does NOT alter nmap output)
set -euo pipefail
IFS=$'\n\t'

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
  echo "Usage: $0 <target>"
  exit 1
fi

NMAP_BIN="$(command -v nmap || true)"
if [ -z "$NMAP_BIN" ]; then
  echo "nmap not found in PATH" >&2
  exit 2
fi

# colors used only for the small summary printed by the script
NC='\e[0m'; BOLD='\e[1m'
RED='\e[31m'; GREEN='\e[32m'; YELLOW='\e[33m'; CYAN='\e[36m'; MAGENTA='\e[35m'

TS=$(date +%Y%m%d_%H%M%S)
FIRST_GREP="nmap_full_${TARGET}_${TS}.gnmap"   # grepable (first scan)
SECOND_HUMAN="nmap_services_${TARGET}_${TS}.nmap" # human-readable (second scan)

echo -e "${BOLD}${CYAN}[*] Target:${NC} $TARGET"
echo -e "${YELLOW}Tip:${NC} Press Enter while nmap runs to print a live status line (native nmap behavior)."

# ----------------- FIRST SCAN -----------------
echo -e "${BOLD}${CYAN}\n=== FIRST SCAN: full TCP sweep (-p- -Pn) ===${NC}"
echo -e "${BOLD}Running:${NC} sudo $NMAP_BIN -p- -Pn $TARGET -oG $FIRST_GREP"
# Run nmap attached to terminal; it writes the grepable file and prints to stdout.
sudo "$NMAP_BIN" -p- -Pn "$TARGET" -oG "$FIRST_GREP"

# Parse open ports from grepable output (only 'open' ports)
PORTS=$(awk -F'Ports: ' '/Ports:/{print $2}' "$FIRST_GREP" \
  | tr ',' '\n' \
  | awk -F'/' '$2=="open"{print $1}' \
  | paste -sd, - | sed 's/^,*//; s/,*$//; s/ //g')

if [ -z "$PORTS" ]; then
  echo -e "${RED}[!] No open ports found in the first scan. Exiting.${NC}"
  echo "Saved: $FIRST_GREP"
  exit 0
fi

# ----------------- Small safe summary (script-only) -----------------
declare -A LABEL
LABEL[22]="SSH"
LABEL[21]="FTP"
LABEL[23]="TELNET"
LABEL[25]="SMTP"
LABEL[80]="HTTP"
LABEL[443]="HTTPS"
LABEL[139]="NetBIOS"
LABEL[135]="RPC"
LABEL[445]="SMB"
LABEL[3389]="RDP"
LABEL[3306]="MySQL"
LABEL[5985]="WinRM(HTTP)"
LABEL[5986]="WinRM(HTTPS)"
LABEL[47001]="WinRM-API"

echo -e "${BOLD}${MAGENTA}\n=== PORT SUMMARY (from first scan) ===${NC}"
IFS=',' read -ra PARRAY <<< "$PORTS"
for port in "${PARRAY[@]}"; do
  if [[ -n "${LABEL[$port]:-}" ]]; then
    printf "%b%4s/tcp%b  %bOPEN%b  %b[%s]%b\n" "$BOLD$RED" "$port" "$NC" "$GREEN" "$NC" "$YELLOW" "${LABEL[$port]}" "$NC"
  else
    printf "%b%4s/tcp%b  %bOPEN%b\n" "$BOLD$CYAN" "$port" "$NC" "$GREEN" "$NC"
  fi
done
echo -e "${BOLD}${MAGENTA}=====================================${NC}"

# ----------------- SECOND SCAN (writes one human-readable file) -----------------
echo -e "${BOLD}${CYAN}\n=== SECOND SCAN: -p${PORTS} -Pn -sC -sV ===${NC}"
echo -e "${BOLD}Running:${NC} sudo $NMAP_BIN -p${PORTS} -Pn -sC -sV $TARGET -oN $SECOND_HUMAN"
# Run attached to terminal and save human-readable output to file
sudo "$NMAP_BIN" -p"$PORTS" -Pn -sC -sV "$TARGET" -oN "$SECOND_HUMAN"

echo -e "${BOLD}${GREEN}\n[*] Done.${NC}"
echo "Saved:"
echo "  First (grepable):  $FIRST_GREP"
echo "  Second (human):    $SECOND_HUMAN"
