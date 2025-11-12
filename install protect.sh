#!/usr/bin/env bash
set -euo pipefail

# ============================================
# installprotect.sh
# Menu launcher yang menjalankan token bash
# persis seperti yang ada di gambar.
# ============================================

# Daftar token (persis seperti di gambar)
TOKENS=(
"bash <(curl -s https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main/1Anti-Delete-Server.sh)"
"bash <(curl -s https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main/2anti-hapus-user.sh)"
"bash <(curl -s https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main/3Anti-Akses-Location.sh)"
"bash <(curl -s https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main/4Anti-Akses-nodes.sh)"
"bash <(curl -s https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main/5Anti-Akses-Nest.sh)"
"bash <(curl -s https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main/6Anti-Akses-File.sh)"
"bash <(curl -s https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main/7Anti-Akses-Settings.sh)"
"bash <(curl -s https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main/8Anti-Akses-Server.sh)"
"bash <(curl -s https://raw.githubusercontent.com/shaaaiu/installprotectpanel/refs/heads/main/9Anti-Modifikasi-Server.sh)"
)

# Print header
echo "======== installprotect.sh launcher ========"

print_menu() {
  cat <<'MENU'
PILIHAN:
1. 1Anti-Delete-Server.sh
2. 2anti-hapus-user.sh
3. 3Anti-Akses-Location.sh
4. 4Anti-Akses-nodes.sh
5. 5Anti-Akses-Nest.sh
6. 6Anti-Akses-File.sh
7. 7Anti-Akses-Settings.sh
8. 8Anti-Akses-Server.sh
9. 9Anti-Modifikasi-Server.sh

 A) Jalankan semua (1→9)
 L) Tampilkan semua token (copyable)
 Q) Keluar
MENU
}

# Menampilkan cuplikan pertama dari script remote (safety check)
show_remote_head() {
  local url="$1"
  echo "----- Menampilkan 40 baris pertama dari: $url -----"
  # gunakan curl untuk menampilkan cuplikan tanpa menyimpan
  if ! curl -fsSL "$url" | sed -n '1,40p'; then
    echo "[Gagal menampilkan cuplikan dari $url]" >&2
  fi
  echo "----- Akhir cuplikan -----"
}

# Jalankan token persis seperti di TOKENS (yang memakai process substitution)
run_token_by_index() {
  local idx="$1"      # 0-based
  local token="${TOKENS[$idx]}"
  # Extract URL for preview
  local url
  url="$(echo "$token" | sed -n "s/.*curl -s \([^)]*\)).*/\1/p" || true)"
  if [[ -n "$url" ]]; then
    show_remote_head "$url"
  fi

  read -rp "Jalankan token nomor $((idx+1)) sekarang? [y/N]: " confirm
  confirm="${confirm,,}"
  if [[ "$confirm" == "y" || "$confirm" == "yes" ]]; then
    echo "Menjalankan: $token"
    # eval akan menjalankan bentuk "bash <(curl -s URL)"
    eval "$token"
    echo "Selesai token $((idx+1))."
  else
    echo "Dibatalkan."
  fi
}

# Jalankan tanpa cuplikan (non-interactive) — langsung eval token
run_token_direct() {
  local idx="$1"
  local token="${TOKENS[$idx]}"
  echo "Menjalankan langsung token $((idx+1)) ..."
  eval "$token"
}

# Tampilkan semua token agar mudah di-copy (sesuai permintaan)
print_all_tokens() {
  echo "------ Semua token (copyable) ------"
  for i in "${!TOKENS[@]}"; do
    printf "%2d) %s\n" "$((i+1))" "${TOKENS[$i]}"
  done
  echo "------------------------------------"
}

# Jika argumen diberikan: angka 1-9 atau A untuk all
if [[ "${1:-}" != "" ]]; then
  arg="$1"
  if [[ "$arg" =~ ^[1-9]$ ]]; then
    # jalankan non-interactive (langsung)
    run_token_direct "$((arg-1))"
    exit 0
  elif [[ "$arg" =~ ^[Aa]$ ]]; then
    for i in "${!TOKENS[@]}"; do
      run_token_direct "$i" || { echo "Terhenti pada token $((i+1))"; exit 1; }
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
      run_token_by_index "$idx"
      ;;
    *)
      echo "Pilihan tidak dikenali. Coba lagi."
      ;;
  esac
  echo
done
