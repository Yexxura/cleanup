#!/bin/bash

# Complete Android Studio Removal Script with Root Privileges
# WARNING: This script requires root access and performs system-wide cleanup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ This script must be run as root${NC}"
    echo "Usage: sudo $0"
    exit 1
fi

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING:${NC} $1"
}

success() {
    echo -e "${GREEN}✅${NC} $1"
}

error() {
    echo -e "${RED}❌${NC} $1"
}

critical() {
    echo -e "${PURPLE}🔥 CRITICAL:${NC} $1"
}

# Function to safely remove with root privileges
root_remove() {
    local path="$1"
    local description="$2"
    
    if [[ -e "$path" ]]; then
        log "Removing $description: $path"
        if [[ -d "$path" ]]; then
            rm -rf "$path"
        else
            rm -f "$path"
        fi
        success "Removed $description"
    else
        log "Not found: $description ($path)"
    fi
}

# Function to kill processes
kill_processes() {
    local process_name="$1"
    local pids=$(pgrep -f "$process_name" 2>/dev/null || true)
    
    if [[ -n "$pids" ]]; then
        log "Killing $process_name processes: $pids"
        kill -9 $pids 2>/dev/null || true
        success "Killed $process_name processes"
    fi
}

# Function to remove from all users
remove_from_all_users() {
    local relative_path="$1"
    local description="$2"
    
    for user_home in /home/*; do
        if [[ -d "$user_home" ]]; then
            local full_path="$user_home/$relative_path"
            root_remove "$full_path" "$description for $(basename "$user_home")"
        fi
    done
    
    # Also check root home
    local root_path="/root/$relative_path"
    root_remove "$root_path" "$description for root"
}

echo "🔥 COMPLETE ANDROID STUDIO SYSTEM-WIDE REMOVAL"
echo "=============================================="
critical "THIS SCRIPT WILL PERFORM DESTRUCTIVE SYSTEM-WIDE CLEANUP"
echo ""
warning "This script will remove:"
echo "   🗑️  ALL Android Studio installations (system-wide)"
echo "   🗑️  ALL Android SDK/NDK installations"
echo "   🗑️  ALL user AVD and emulator data"
echo "   🗑️  ALL Gradle installations and caches"
echo "   🗑️  ALL development certificates and keys"
echo "   🗑️  ALL related system packages and services"
echo "   🗑️  ALL Flutter/Dart/React Native installations"
echo "   🗑️  ALL build caches and temporary files"
echo "   🗑️  ALL desktop entries and system configurations"
echo "   🗑️  ALL related processes and services"
echo ""
critical "THIS CANNOT BE UNDONE!"
echo ""
read -p "❓ Are you absolutely sure you want to continue? (type 'DELETE' to confirm): " confirm
[[ "$confirm" != "DELETE" ]] && { error "Cancelled for safety."; exit 0; }

log "Starting COMPLETE Android Studio system removal..."

# ================================
# 1. Kill All Related Processes
# ================================
log "💀 [1/25] Killing all Android Studio related processes..."

PROCESS_NAMES=(
    "studio"
    "android-studio"
    "gradle"
    "adb"
    "fastboot"
    "emulator"
    "qemu"
    "flutter"
    "dart"
)

for process in "${PROCESS_NAMES[@]}"; do
    kill_processes "$process"
done

# Kill Java processes that might be Android Studio
pgrep -f "idea.Main" | xargs -r kill -9 2>/dev/null || true
pgrep -f "com.android" | xargs -r kill -9 2>/dev/null || true

# ================================
# 2. Stop System Services
# ================================
log "⚙️ [2/25] Stopping system services..."

# Stop adb server
adb kill-server 2>/dev/null || true

# Stop any systemd services
systemctl stop android-studio* 2>/dev/null || true
systemctl disable android-studio* 2>/dev/null || true

# ================================
# 3. Remove APT/DEB Packages
# ================================
log "📦 [3/25] Removing APT packages..."

# Find and remove Android-related packages
ANDROID_PACKAGES=$(dpkg -l 2>/dev/null | grep -E "(android|studio)" | awk '{print $2}' || true)
if [[ -n "$ANDROID_PACKAGES" ]]; then
    echo "$ANDROID_PACKAGES" | while read -r package; do
        log "Removing package: $package"
        apt remove --purge -y "$package" 2>/dev/null || true
    done
fi

# Remove specific common packages
apt remove --purge -y android-sdk* android-studio* 2>/dev/null || true

# ================================
# 4. Remove Snap Packages
# ================================
log "📦 [4/25] Removing snap packages..."

if command -v snap &> /dev/null; then
    ANDROID_SNAPS=$(snap list 2>/dev/null | grep -E "(android|flutter|studio)" | awk '{print $1}' || true)
    if [[ -n "$ANDROID_SNAPS" ]]; then
        echo "$ANDROID_SNAPS" | while read -r snap_name; do
            log "Removing snap: $snap_name"
            snap remove "$snap_name" 2>/dev/null || true
        done
    fi
fi

# ================================
# 5. Remove Flatpak Packages
# ================================
log "📦 [5/25] Removing flatpak packages..."

if command -v flatpak &> /dev/null; then
    flatpak uninstall --system -y com.google.AndroidStudio 2>/dev/null || true
    flatpak uninstall --user -y com.google.AndroidStudio 2>/dev/null || true
fi

# ================================
# 6. Remove System-wide Installations
# ================================
log "🗂️ [6/25] Removing system-wide installations..."

SYSTEM_LOCATIONS=(
    "/opt/android-studio"
    "/usr/local/android-studio"
    "/usr/share/android-studio"
    "/opt/android-sdk"
    "/usr/local/android-sdk"
    "/opt/flutter"
    "/usr/local/flutter"
    "/opt/dart-sdk"
    "/usr/local/dart-sdk"
)

for location in "${SYSTEM_LOCATIONS[@]}"; do
    root_remove "$location" "System installation"
done

# ================================
# 7. Remove User Installations (All Users)
# ================================
log "👥 [7/25] Removing user installations from all users..."

USER_LOCATIONS=(
    "android-studio"
    ".local/share/JetBrains/Toolbox/apps/AndroidStudio"
    "Android/Sdk"
    "android-sdk"
    "android-ndk"
    "flutter"
    "dart-sdk"
    ".android"
    ".gradle"
    ".flutter"
    ".dart"
    ".pub-cache"
)

for location in "${USER_LOCATIONS[@]}"; do
    remove_from_all_users "$location" "User installation"
done

# ================================
# 8. Remove Build Caches System-wide
# ================================
log "🗄️ [8/25] Removing build caches system-wide..."

# Find and remove build directories
find /home -name "build" -type d -path "*/android/*" -exec rm -rf {} + 2>/dev/null || true
find /home -name ".gradle" -type d -exec rm -rf {} + 2>/dev/null || true
find /root -name "build" -type d -path "*/android/*" -exec rm -rf {} + 2>/dev/null || true
find /root -name ".gradle" -type d -exec rm -rf {} + 2>/dev/null || true

# ================================
# 9. Remove APK/AAB Files System-wide
# ================================
log "📱 [9/25] Removing APK/AAB files system-wide..."

find /home -name "*.apk" -type f -delete 2>/dev/null || true
find /home -name "*.aab" -type f -delete 2>/dev/null || true
find /root -name "*.apk" -type f -delete 2>/dev/null || true
find /root -name "*.aab" -type f -delete 2>/dev/null || true

# ================================
# 10. Remove System Binaries
# ================================
log "🔧 [10/25] Removing system binaries..."

SYSTEM_BINARIES=(
    "/usr/bin/android-studio"
    "/usr/local/bin/android-studio"
    "/usr/bin/studio"
    "/usr/local/bin/studio"
    "/usr/bin/flutter"
    "/usr/local/bin/flutter"
    "/usr/bin/dart"
    "/usr/local/bin/dart"
)

for binary in "${SYSTEM_BINARIES[@]}"; do
    root_remove "$binary" "System binary"
done

# ================================
# 11. Remove Desktop Entries System-wide
# ================================
log "🖥️ [11/25] Removing desktop entries system-wide..."

DESKTOP_LOCATIONS=(
    "/usr/share/applications/android-studio.desktop"
    "/usr/share/applications/jetbrains-android-studio.desktop"
    "/usr/local/share/applications/android-studio.desktop"
)

for desktop in "${DESKTOP_LOCATIONS[@]}"; do
    root_remove "$desktop" "System desktop entry"
done

# Remove from all users
remove_from_all_users ".local/share/applications/android-studio.desktop" "User desktop entry"
remove_from_all_users ".local/share/applications/jetbrains-android-studio.desktop" "User desktop entry"

# ================================
# 12. Clean System Libraries
# ================================
log "📚 [12/25] Cleaning system libraries..."

# Remove Android-related libraries
find /usr/lib -name "*android*" -delete 2>/dev/null || true
find /usr/local/lib -name "*android*" -delete 2>/dev/null || true

# ================================
# 13. Clean System Include Files
# ================================
log "📋 [13/25] Cleaning system include files..."

root_remove "/usr/include/android" "System include files"
root_remove "/usr/local/include/android" "Local include files"

# ================================
# 14. Remove Environment Variables
# ================================
log "🌍 [14/25] Cleaning environment variables..."

# Clean system-wide environment
ENV_FILES=(
    "/etc/environment"
    "/etc/profile"
    "/etc/bash.bashrc"
    "/etc/zsh/zshrc"
)

for env_file in "${ENV_FILES[@]}"; do
    if [[ -f "$env_file" ]]; then
        log "Cleaning Android variables from $env_file"
        cp "$env_file" "${env_file}.backup.$(date +%Y%m%d_%H%M%S)"
        sed -i '/ANDROID_HOME/d; /ANDROID_SDK_ROOT/d; /FLUTTER_ROOT/d; /DART_SDK/d' "$env_file"
    fi
done

# Clean user environments
for user_home in /home/* /root; do
    if [[ -d "$user_home" ]]; then
        USER_ENV_FILES=(
            ".bashrc"
            ".zshrc"
            ".profile"
            ".bash_profile"
        )
        
        for env_file in "${USER_ENV_FILES[@]}"; do
            full_path="$user_home/$env_file"
            if [[ -f "$full_path" ]]; then
                log "Cleaning Android variables from $full_path"
                cp "$full_path" "${full_path}.backup.$(date +%Y%m%d_%H%M%S)"
                sed -i '/ANDROID_HOME/d; /ANDROID_SDK_ROOT/d; /FLUTTER_ROOT/d; /DART_SDK/d; /android-sdk/d; /flutter/d; /dart/d' "$full_path"
            fi
        done
    fi
done

# ================================
# 15. Remove Systemd Services
# ================================
log "⚙️ [15/25] Removing systemd services..."

find /etc/systemd/system -name "*android*" -delete 2>/dev/null || true
find /etc/systemd/system -name "*studio*" -delete 2>/dev/null || true
systemctl daemon-reload

# ================================
# 16. Clean Temporary Files
# ================================
log "🗑️ [16/25] Cleaning temporary files..."

# Clean /tmp
find /tmp -name "*android*" -delete 2>/dev/null || true
find /tmp -name "*studio*" -delete 2>/dev/null || true
find /tmp -name "*.apk" -delete 2>/dev/null || true

# Clean /var/tmp
find /var/tmp -name "*android*" -delete 2>/dev/null || true
find /var/tmp -name "*studio*" -delete 2>/dev/null || true

# ================================
# 17. Clean Log Files
# ================================
log "📜 [17/25] Cleaning log files..."

# Clean specific log entries (safer than deleting entire logs)
if [[ -f /var/log/syslog ]]; then
    cp /var/log/syslog /var/log/syslog.backup.$(date +%Y%m%d_%H%M%S)
    sed -i '/android-studio\|Android\|emulator/d' /var/log/syslog
fi

# ================================
# 18. Remove Cache Directories
# ================================
log "🗄️ [18/25] Removing cache directories..."

CACHE_PATTERNS=(
    ".cache/android-studio"
    ".cache/JetBrains/AndroidStudio*"
    ".cache/gradle"
    ".cache/flutter"
    ".cache/dart"
)

for pattern in "${CACHE_PATTERNS[@]}"; do
    remove_from_all_users "$pattern" "Cache directory"
done

# ================================
# 19. Remove Development Certificates
# ================================
log "🔐 [19/25] Removing development certificates..."

CERT_PATTERNS=(
    ".android/debug.keystore"
    ".android/adbkey*"
    "*release-key.keystore"
    "keystore.jks"
)

for pattern in "${CERT_PATTERNS[@]}"; do
    remove_from_all_users "$pattern" "Development certificate"
done

# ================================
# 20. Clean Package Manager Caches
# ================================
log "📦 [20/25] Cleaning package manager caches..."

apt clean
apt autoremove --purge -y

if command -v snap &> /dev/null; then
    snap refresh
fi

# ================================
# 21. Remove Browser Downloads
# ================================
log "🌐 [21/25] Removing Android files from browser downloads..."

for user_home in /home/* /root; do
    if [[ -d "$user_home" ]]; then
        DOWNLOAD_DIRS=(
            "Downloads"
            "Desktop"
            "Documents"
        )
        
        for dir in "${DOWNLOAD_DIRS[@]}"; do
            if [[ -d "$user_home/$dir" ]]; then
                find "$user_home/$dir" -name "*android*" -type f -delete 2>/dev/null || true
                find "$user_home/$dir" -name "*studio*" -type f -delete 2>/dev/null || true
                find "$user_home/$dir" -name "*.apk" -type f -delete 2>/dev/null || true
            fi
        done
    fi
done

# ================================
# 22. Remove Configuration Files
# ================================
log "⚙️ [22/25] Removing configuration files..."

CONFIG_PATTERNS=(
    ".IntelliJIdea*/config/plugins/android"
    ".config/android-studio"
    ".config/JetBrains/AndroidStudio*"
)

for pattern in "${CONFIG_PATTERNS[@]}"; do
    remove_from_all_users "$pattern" "Configuration files"
done

# ================================
# 23. Clean Command History
# ================================
log "📚 [23/25] Cleaning command history..."

for user_home in /home/* /root; do
    if [[ -d "$user_home" ]]; then
        HISTORY_FILES=(
            ".bash_history"
            ".zsh_history"
        )
        
        for history_file in "${HISTORY_FILES[@]}"; do
            full_path="$user_home/$history_file"
            if [[ -f "$full_path" ]]; then
                cp "$full_path" "${full_path}.backup.$(date +%Y%m%d_%H%M%S)"
                sed -i '/android\|studio\|gradle\|flutter\|dart\|adb\|fastboot/Id' "$full_path"
            fi
        done
    fi
done

# ================================
# 24. Update System Databases
# ================================
log "🔄 [24/25] Updating system databases..."

# Update locate database
updatedb 2>/dev/null || true

# Update desktop database
update-desktop-database /usr/share/applications 2>/dev/null || true
for user_home in /home/*; do
    if [[ -d "$user_home/.local/share/applications" ]]; then
        sudo -u $(basename "$user_home") update-desktop-database "$user_home/.local/share/applications" 2>/dev/null || true
    fi
done

# ================================
# 25. Final System Cleanup
# ================================
log "✨ [25/25] Final system cleanup..."

# Clear system caches
sync
echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

# Remove empty directories
find /home -type d -empty -path "*android*" -delete 2>/dev/null || true
find /home -type d -empty -path "*studio*" -delete 2>/dev/null || true

echo ""
success "🔥 COMPLETE ANDROID STUDIO SYSTEM REMOVAL FINISHED!"
echo ""
critical "SYSTEM-WIDE REMOVAL SUMMARY:"
log "   🗑️  All Android Studio installations removed"
log "   🗑️  All Android SDK/NDK removed"
log "   🗑️  All user data and configurations removed"
log "   🗑️  All system packages and services removed"
log "   🗑️  All development tools and caches removed"
log "   🗑️  All related processes terminated"
log "   🗑️  All environment variables cleaned"
log "   🗑️  All desktop entries removed"
log "   🗑️  All certificates and keys removed"
log "   🗑️  All temporary and cache files removed"
echo ""
warning "Configuration backups created with timestamp suffixes"
warning "A system reboot is STRONGLY recommended"
echo ""
read -p "🔄 Reboot system now? (y/N): " reboot_confirm
if [[ "$reboot_confirm" =~ ^[Yy]$ ]]; then
    log "Rebooting system..."
    reboot
else
    warning "Please reboot manually to complete the removal process"
fi

success "Android Studio has been completely removed from the system! 🎉"
