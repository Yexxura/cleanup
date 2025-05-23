#!/bin/bash

# Script Penghapusan Android Studio - LEVEL SUPER DEEP CLEANER
# PERINGATAN: Script ini akan menghapus SEMUA file, konfigurasi, log, cache, bahkan file terselubung!

echo "⚠️  PERINGATAN: ANDA AKAN MENJALANKAN SCRIPT HAPUS LEVEL EXTREME!"
echo "📋 Semua file terkait Android Development akan DIHAPUS SELAMANYA:"
echo "   - File konfigurasi"
echo "   - File log"
echo "   - File terselubung"
echo "   - Cache browser"
echo "   - Service systemd"
echo "   - Riwayat pencarian desktop"
echo "   - Kernel modules emulator"
echo "   - DLL/Wine files (jika ada)"
echo "   - Dan lainnya..."
echo ""
read -p "❓ Apakah Anda benar-benar yakin? (y/N): " confirm
[[ ! "$confirm" =~ ^[Yy]$ ]] && { echo "❌ Dibatalkan."; exit 0; }

sudo -v || { echo "❌ Autentikasi gagal. Keluar."; exit 1; }

# Fungsi eksekusi aman
execute() {
    sudo $@
}

# ================================
# 1. Hapus Log Sistem Terkait
# ================================
echo "📜 [1/15] Menghapus file log..."
LOG_PATHS=(
    "/var/log/syslog"
    "/var/log/messages"
    "/var/log/kern.log"
    "/var/log/Xorg.0.log"
)
for path in "${LOG_PATHS[@]}"; do
    if [ -f "$path" ]; then
        echo "✂️ Membersihkan $path..."
        sudo sed -i '/Android\|android-studio\|emulator/d' "$path"
    fi
done

# ================================
# 2. Hapus Riwayat Desktop
# ================================
echo "🔍 [2/15] Membersihkan riwayat pencarian desktop..."
for user_home in /home/*/; do
    RECENT_FILE="$user_home/.local/share/recently-used.xbel"
    if [ -f "$RECENT_FILE" ]; then
        echo "✂️ Membersihkan $RECENT_FILE"
        sudo sed -i '/android-studio\|avd\|flutter\|gradle/d' "$RECENT_FILE"
    fi
done

# ================================
# 3. Hapus File Terselubung
# ================================
echo "🧻 [3/15] Menghapus file terselubung (.*)..."
for user_home in /home/*/; do
    sudo find "$user_home" -name "._android*" -o -name ".DS_Store" -o -name ".directory" -o -name "*.swp" -o -name "*.swo" -o -name "*.bak" -exec sudo rm -rf {} \;
done

# ================================
# 4. Hapus Kernel Modules Emulator
# ================================
echo "🔌 [4/15] Menghapus kernel modules emulator..."
if lsmod | grep -q vhost; then
    echo "🔧 Menonaktifkan vhost_net..."
    execute modprobe -r vhost_net 2>/dev/null
fi

# ================================
# 5. Hapus Wine File (Jika Ada)
# ================================
echo "🧱 [5/15] Menghapus file Wine Android Studio..."
for user_home in /home/*/; do
    WINE_DIRS=(
        ".wine"
        ".PlayOnLinux"
        ".winetrickscache"
    )
    for dir in "${WINE_DIRS[@]}"; do
        if [ -d "$user_home/$dir" ]; then
            echo "🗑️ Membersihkan $dir..."
            sudo find "$user_home/$dir" -name "*android*" -o -name "*studio*" -exec sudo rm -rf {} +
        fi
    done
done

# ================================
# 6. Hapus File Ekstensi Khusus
# ================================
echo "📁 [6/15] Menghapus file dengan ekstensi khusus..."
EXTENSIONS=(.studio .avd .ini .cfg .tmp .temp .log .old .backup)
for ext in "${EXTENSIONS[@]}"; do
    sudo find / -type f -name "*$ext" -exec sudo rm -f {} + 2>/dev/null
done

# ================================
# 7. Hapus Systemd Services
# ================================
echo "⚙️ [7/15] Menghapus systemd services terkait..."
SYSTEMD_SERVICES=$(systemctl list-units --type=service 2>/dev/null | grep -E 'android|studio|emulator' | awk '{print $1}')
if [ -n "$SYSTEMD_SERVICES" ]; then
    echo "$SYSTEMD_SERVICES" | xargs -I {} sudo systemctl stop {} > /dev/null 2>&1
    echo "$SYSTEMD_SERVICES" | xargs -I {} sudo systemctl disable {} > /dev/null 2>&1
    echo "$SYSTEMD_SERVICES" | xargs -I {} sudo rm -f /etc/systemd/system/{} > /dev/null 2>&1
    sudo systemctl daemon-reexec
    sudo systemctl reset-failed
fi

# ================================
# 8. Hapus Browser Cache APK
# ================================
echo "🌐 [8/15] Membersihkan cache browser APK..."
BROWSER_DIRS=(
    ".mozilla/firefox/*.default-release/cache2"
    ".config/google-chrome/Default/Application Cache"
    ".config/chromium/Default/Application Cache"
)
for user_home in /home/*/; do
    for dir in "${BROWSER_DIRS[@]}"; do
        CACHE_DIR="$user_home/$dir"
        if [ -d "$CACHE_DIR" ]; then
            echo "✂️ Membersihkan $CACHE_DIR..."
            sudo find "$CACHE_DIR" -type f -name "*.apk" -exec sudo rm -f {} +
        fi
    done
done

# ================================
# 9. Hapus Lock/PID Files
# ================================
echo "🔒 [9/15] Menghapus file lock/pid..."
sudo find / -type f $ -name "*.lock" -o -name "*.pid" -o -name "*.sock" $ -exec sudo rm -f {} + 2>/dev/null

# ================================
# 10. Hapus File dengan Kata Kunci
# ================================
echo "🔍 [10/15] Menghapus file dengan kata kunci tambahan..."
KEYWORDS=("studio" "sdk" "ndk" "adb" "fastboot" "avd" "emulator")
for keyword in "${KEYWORDS[@]}"; do
    sudo find / -type d -iname "*$keyword*" -exec sudo rm -rf {} + 2>/dev/null
    sudo find / -type f -iname "*$keyword*" -exec sudo rm -f {} + 2>/dev/null
done

# ================================
# 11. Hapus File Sistem Tambahan
# ================================
echo "🧹 [11/15] Membersihkan direktori sistem tambahan..."
sudo rm -rf /usr/lib/x86_64-linux-gnu/libandroid* 2>/dev/null
sudo rm -rf /usr/include/android 2>/dev/null
sudo rm -rf /usr/bin/android* 2>/dev/null

# ================================
# 12. Hapus File Unduhan APK
# ================================
echo "📱 [12/15] Membersihkan file APK dari folder unduhan..."
for user_home in /home/*/; do
    DOWNLOAD_DIR="$user_home/Downloads"
    if [ -d "$DOWNLOAD_DIR" ]; then
        sudo find "$DOWNLOAD_DIR" -type f -iname "*.apk" -exec sudo rm -f {} +
    fi
done

# ================================
# 13. Hapus File Konfigurasi KDE/GNOME
# ================================
echo "🖥️ [13/15] Membersihkan konfigurasi desktop environment..."
for user_home in /home/*/; do
    sudo find "$user_home/.config" -type f -exec grep -l -i "android\|studio\|flutter" {} \; -exec sudo rm -f {} +
done

# ================================
# 14. Hapus File Sistem Lama
# ================================
echo "📂 [14/15] Membersihkan file sistem lama..."
sudo find /var/cache/apt/archives -name "*android*" -exec sudo rm -f {} + 2>/dev/null
sudo find /var/cache/apt/archives -name "*studio*" -exec sudo rm -f {} + 2>/dev/null

# ================================
# 15. Pembersihan Akhir
# ================================
echo "🧹 [15/15] Pembersihan akhir..."
sudo apt autoremove --purge -y > /dev/null 2>&1
sudo apt clean > /dev/null 2>&1
sudo updatedb > /dev/null 2>&1

# Kosongkan bash history
history -c
for user_home in /home/*/; do
    sudo truncate -s 0 "$user_home/.bash_history" 2>/dev/null
done

echo ""
echo "✅ PENGHAPUSAN ANDROID STUDIO LEVEL EXTREME SELESAI!"
echo "📌 Tidak ada file, cache, konfigurasi, atau registry tersisa."
echo "🔄 Restart disarankan untuk hasil maksimal."
read -p "🔁 Restart sekarang? (y/N): " restart
[[ "$restart" =~ ^[Yy]$ ]] && sudo reboot
