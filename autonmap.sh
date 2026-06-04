#!/bin/bash

# ─────────────────────────────────────────────────────────────────────────
# autoNmap — Automated Reconnaissance Tool (Bash)
# Author  : Daniel Fadrique
# GitHub  : github.com/DanielFadrique
# Desc    : Full port scan automation con service detection y
#           web fingerprinting. extractPorts integrado en Fase 2.
#
# Usage   : ./recon.sh <IP>
#           ./recon.sh <IP> [output_dir]
# ─────────────────────────────────────────────────────────────────────────

# ── COLORS ────────────────────────────────────────────────────────────────

RESET="\033[0m"
BOLD="\033[1m"
RED="\033[91m"
GREEN="\033[92m"
YELLOW="\033[93m"
BLUE="\033[94m"
CYAN="\033[96m"
WHITE="\033[97m"
GRAY="\033[90m"

# ── HELPERS ───────────────────────────────────────────────────────────────

info()    { echo -e "${BLUE}[*]${RESET} $1"; }
success() { echo -e "${GREEN}[+]${RESET} ${BOLD}$1${RESET}"; }
warning() { echo -e "${YELLOW}[!]${RESET} $1"; }
error()   { echo -e "${RED}[-]${RESET} $1"; }

section() {
    local line="───────────────────────────────────────────────────────"
    echo -e "\n${CYAN}${line}"
    echo -e "  ${BOLD}$1${RESET}${CYAN}"
    echo -e "${line}${RESET}\n"
}

banner() {
    echo -e "${CYAN}${BOLD}"
    echo "  ██████╗██╗   ██╗████████╗ ██████╗ ███╗   ██╗███╗   ███╗ █████╗ ██████╗"
    echo " ██╔══██╗██║   ██║╚══██╔══╝██╔═══██╗████╗  ██║████╗ ████║██╔══██╗██╔══██╗"
    echo " ███████║██║   ██║   ██║   ██║   ██║██╔██╗ ██║██╔████╔██║███████║██████╔╝"
    echo " ██╔══██║██║   ██║   ██║   ██║   ██║██║╚██╗██║██║╚██╔╝██║██╔══██║██╔═══╝"
    echo " ██║  ██║╚██████╔╝   ██║   ╚██████╔╝██║ ╚████║██║ ╚═╝ ██║██║  ██║██║"
    echo " ╚═╝  ╚═╝ ╚═════╝    ╚═╝    ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝"
    echo -e "${RESET}${GRAY}                       autoNmap — by Daniel Fadrique"
    echo -e "           ─────────────────────────────────────────────${RESET}"
    echo
}

# ── PORT CHECK ────────────────────────────────────────────────────────────

port_is_open() {
    echo "$2" | tr ',' '\n' | grep -qx "$1"
}

# ── WHATWEB ───────────────────────────────────────────────────────────────

run_whatweb() {
    local ip="$1"
    local output_file="$2"

    section "WEB FINGERPRINTING — WhatWeb"
    warning "Port 80 detected open on ${ip}. Running WhatWeb..."

    if ! command -v whatweb &>/dev/null; then
        warning "whatweb not found, try: sudo apt install whatweb"
        return 1
    fi

    whatweb "http://${ip}" -v --color=always | tee "$output_file"
    success "WhatWeb output saved → ${output_file}"
}


main() {
    banner

    if [[ $# -lt 1 ]]; then
        error "Usage: $0 <IP> [output_dir]"
        exit 1
    fi

    local ip="$1"

    if ! [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        error "Invalid IP address: ${ip}"
        exit 1
    fi

    local output_dir="$(dirname "$0")/autonmap"
    mkdir -p "$output_dir"
    success "Results directory: ${output_dir}"

    local allports_file="${output_dir}/allPorts"
    local targeted_file="${output_dir}/targeted"
    local whatweb_file="${output_dir}/whatweb"

    # ── FASE 1 — Escaneo completo ─────────────────────────────────────────
    section "PHASE 1 — Full Machine Scan"
    info "Target: ${WHITE}${BOLD}${ip}${RESET}"
    info "Scanning all 65535 ports with --min-rate 5000..."

    nmap -p- --open --min-rate 5000 -vvv -n -Pn "$ip" -oG "$allports_file"
    success "Full scan saved → ${allports_file}"

    # ── FASE 2 — Extracción de puertos ──────────
    section "PHASE 2 — Extracting Open Ports"
    sleep 2

    # Función que coge los puertos abiertos
    ports="$(cat "$allports_file" | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    ip_address="$(cat "$allports_file" | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"

    echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
    echo -e "\t[*] IP Address: $ip_address"       >> extractPorts.tmp
    echo -e "\t[*] Open ports: $ports\n"           >> extractPorts.tmp

    # Comprobar xclip en el sistema y copiar puertos abiertos a la clipboard
    if command -v xclip &>/dev/null; then
        echo "$ports" | tr -d '\n' | xclip -sel clip
        echo -e "[*] Ports copied to clipboard\n"  >> extractPorts.tmp
    else
        echo -e "[!] xclip not found, ports not copied, try: sudo apt install xclip.\n" >> extractPorts.tmp
    fi

    # Utilizar bat para mostrar los datos, si no, utilizar cat
    if command -v bat &>/dev/null; then
        bat extractPorts.tmp
    else
        cat extractPorts.tmp -l java
    fi

    rm extractPorts.tmp

    if [[ -z "$ports" ]]; then
        error "No open ports found. Exiting."
        exit 0
    fi

    # ── FASE 3 — Escaneo de servicios ────────────────────────────────────
    section "PHASE 3 — Service & Version Detection"
    info "Running detailed scan on ports: ${GREEN}${ports}${RESET}"

    nmap -sCV -p"${ports}" "$ip" -oN "$targeted_file"
    success "Targeted scan saved → ${targeted_file}"
    sleep 2

    # ── FASE 4 — Fingerprinting con Whatweb ────────────────────────────
    if port_is_open "80" "$ports"; then
        run_whatweb "$ip" "$whatweb_file"
    else
        info "Port 80 not detected. Skipping WhatWeb."
    fi

    # ── RESUMEN FINAL ─────────────────────────────────────────────────────
    section "SCAN COMPLETE"
    success "Target:       ${ip}"
    success "Open ports:   ${ports}"
    success "Results dir:  ${output_dir}"

    echo -e "\n  ${GRAY}Files generated:${RESET}"
    for fname in allPorts targeted whatweb; do
        local fpath="${output_dir}/${fname}"
        if [[ -f "$fpath" ]]; then
            local size
            size="$(wc -c < "$fpath")"
            echo -e "  ${CYAN}→${RESET} $(printf '%-12s' "$fname") ${GRAY}(${size} bytes)${RESET}"
        fi
    done
    echo
}

main "$@"

