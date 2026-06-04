# AUTONMAP
# CTF recon — Automated Reconnaissance Tool

**Author:** Daniel Fadrique  
**GitHub:** github.com/DanielFadrique

Herramienta de reconocimiento automatizado para entornos CTF y laboratorios de pentesting.

NOTA: esta herramienta es para uso etico. 


---

## Flujo de trabajo

```
1. nmap -p- --min-rate 5000 -n -Pn (full port scan)  →  escanea todos los puertos
2. extractPorts()             →  extrae los puertos descubiertos
3. nmap -sCV (targeted scan)  →  busca que servicios y versiones tiene la maquina con los puertos
4. whatweb (si puerto 80)     →  analisis extenso de puerto 80 si esta abierto en la maquina
```

---

## Uso


### Bash
```bash
chmod +x recon.sh
./recon.sh <IP>
./recon.sh <IP> /ruta/resultados
```

---

## Requisitos

```bash
# Herramientas necesarias
sudo apt install nmap whatweb xclip
```

---

## Estructura de resultados

```
autonmap/
    ├── allPorts    # Salida grepable del escaneo completo
    ├── targeted    # Salida del escaneo de servicios
    └── whatweb     # Fingerprinting web (si puerto 80 abierto)
```

---

## Ejemplo de salida

```
[*] Target: 10.10.10.1
[*] Scanning all 65535 ports...

┌─ Extraction Results ──────────────
│  IP Address:  10.10.10.1
│  Open Ports:  22,80,443
└───────────────────────────────────

[+] Ports copied to clipboard
[*] Running detailed scan on ports: 22,80,443
[!] Port 80 detected. Running WhatWeb...
```
