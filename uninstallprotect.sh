#!/usr/bin/env bash
set -euo pipefail

# uninstallprotect.sh
# Menu launcher untuk uninstallprotect1..9.sh
# Base URL: https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main

BASE_URL="https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main"

TOKENS=(
"bash <(curl -s ${BASE_URL}/1unin-Anti-Delete-Server.sh)"
"bash <(curl -s ${BASE_URL}/2unin-anti-hapus-user.sh)"
"bash <(curl -s ${BASE_URL}/3unin-Anti-Akses-Location.sh)"
"bash <(curl -s ${BASE_URL}/4unin-Anti-Akses-nodes.sh)"
"bash <(curl -s ${BASE_URL}/5unin-Anti-Akses-Nest.sh)"
"bash <(curl -s ${BASE_URL}/6unin-Anti-Akses-File.sh)"
"bash <(curl -s ${BASE_URL}/7unin-Anti-Akses-Settings.sh)"
"bash <(curl -s ${BASE_URL}/8unin-Anti-Akses-Server.sh)"
"bash <(curl -s ${BASE_URL}/9unin-Anti-Modifikasi-Server.sh)"
)

print_header() {
  cat <<'HDR'
============================================
 uninstallprotect.sh — Uninstall menu (1..9)
============================================
HDR
}

print_menu() {
  cat <<'MENU'
PILIHAN:
1) 1unin-Anti-Delete-Server.sh
2) 2unin-anti-hapus-user.sh
3) 3unin-Anti-Akses-Location.sh
4) 4unin-Anti-Akses-nodes.sh
5) 5unin-Anti-Akses-Nest.sh
6) 6unin-Anti-Akses-File.sh
7) 7unin-Anti-Akses-Settings.sh
8) 8unin-Anti-Akses-Server.sh
9) 9unin-Anti-Modifikasi-Server.sh

 A) Jalankan semua (1→9)
 L) Tampilkan semua token (copyable)
 Q) Keluar
MENU
}

# tampilkan cuplikan pertama (safety preview)
show_remote_head() {
  local url="$1"
  echo
  echo "----- Menampilkan 40 baris pertama dari: $url -----"
  if ! curl -fsSL "$url" | sed -n '1,40p'; then
    echo "[Gagal mengambil cuplikan dari $url]" >&2
  fi
  echo "----- Akhir cuplikan -----"
  echo
}

# extract URL dari token "bash <(curl -s URL)"
extract_url_from_token() {
  local token="$1"
  # ambil bagian setelah 'curl -s ' sampai sebelum ')'
  echo "$token" | awk -F'curl -s ' '{print $2}' | sed 's/).*//'
}

run_token_interactive() {
  local idx="$1"
  local token="${TOKENS[$idx]}"
  local url
  url="$(extract_url_from_token "$token")"
  if [[ -n "$url" ]]; then
    show_remote_head "$url"
  fi
  read -rp "Jalankan uninstallprotect$((idx+1)).sh sekarang? [y/N]: " conf
  conf="${conf,,}"
  if [[ "$conf" == "y" || "$conf" == "yes" ]]; then
    echo "Menjalankan: ${token}"
    eval "$token"
    echo "Selesai uninstallprotect$((idx+1)).sh"
  else
    echo "Dibatalkan."
  fi
}

# jalankan langsung tanpa prompt (dipakai oleh non-interactive / mode A)
run_token_direct() {
  local idx="$1"
  local token="${TOKENS[$idx]}"
  echo "Menjalankan langsung uninstallprotect$((idx+1)).sh ..."
  eval "$token"
  echo "Selesai uninstallprotect$((idx+1)).sh"
}

print_all_tokens() {
  echo
  echo "------ Semua token (copyable) ------"
  for i in "${!TOKENS[@]}"; do
    printf "%2d) %s\n" "$((i+1))" "${TOKENS[$i]}"
  done
  echo "------------------------------------"
  echo
}

# Jika argumen diberikan => non-interactive
if [[ "${1:-}" != "" ]]; then
  arg="$1"
  if [[ "$arg" =~ ^[1-9]$ ]]; then
    run_token_direct "$((arg-1))"
    exit 0
  elif [[ "$arg" =~ ^[Aa]$ ]]; then
    for i in "${!TOKENS[@]}"; do
      run_token_direct "$i" || { echo "Terhenti pada token $((i+1))."; exit 1; }
    done
    exit 0
  elif [[ "$arg" =~ ^[Ll]$ ]]; then
    print_all_tokens
    exit 0
  else
    echo "Argumen tidak valid. Gunakan 1-9, A, atau L." >&2
    exit 2
  fi
fi

# Interactive loop
print_header
while true; do
  print_menu
  read -rp "Masukkan pilihan (1-9, A, L, Q): " choice
  choice="${choice,,}"
  case "$choice" in
    q|quit|exit) echo "Keluar."; exit 0 ;;
    l) print_all_tokens ;;
    a)
      for i in "${!TOKENS[@]}"; do
        echo
        echo ">>> Token $((i+1)):"
        echo "${TOKENS[$i]}"
        read -rp "Jalankan token ini? [y/N]: " c
        c="${c,,}"
        if [[ "$c" == "y" || "$c" == "yes" ]]; then
          run_token_direct "$i" || { echo "Terhenti pada token $((i+1))."; break; }
        else
          echo "Lewati token $((i+1))."
        fi
      done
      ;;
    [1-9])
      idx=$((choice-1))
      run_token_interactive "$idx"
      ;;
    *)
      echo "Pilihan tidak dikenali. Coba lagi."
      ;;
  esac
  echo
done
