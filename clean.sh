#!/bin/bash

# Safe Android Studio Deep Cleaner Script
# Removes Android Studio and related development tools thoroughly but safely

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Function to safely remove files/directories
safe_remove() {
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

# Function to remove files with pattern safely
safe_remove_pattern() {
    local base_dir="$1"
    local pattern="$2"
    local description="$3"
    
    if [[ -d "$base_dir" ]]; then
        log "Searching for $description in $base_dir"
        find "$base_dir" -name "$pattern" -type f 2>/dev/null | while read -r file; do
            log "Removing: $file"
            rm -f "$file"
        done
        find "$base_dir" -name "$pattern" -type d -empty 2>/dev/null | while read -r dir; do
            log "Removing empty directory: $dir"
            rmdir "$dir" 2>/dev/null || true
        done
    fi
}

# Check if running as root (we don't want that for safety)
if [[ $EUID -eq 0 ]]; then
    error "Please don't run this script as root for safety reasons"
    exit 1
fi

echo "🧹 Android Studio Deep Cleaner - Safe Edition"
echo "============================================="
warning "This script will remove ALL Android development tools and data"
echo "📋 Items to be removed:"
echo "   • Android Studio installations"
echo "   • Android SDK and NDK"
echo "   • Gradle caches and wrapper"
echo "   • AVD (Virtual Devices)"
echo "   • IntelliJ IDEA Android plugins"
echo "   • Development certificates and keys"
echo "   • Build caches and temporary files"
echo "   • Flutter SDK (if present)"
echo "   • Dart SDK (if present)"
echo "   • Cordova/PhoneGap files"
echo "   • React Native caches"
echo ""
read -p "❓ Continue with removal? (y/N): " confirm
[[ ! "$confirm" =~ ^[Yy]$ ]] && { echo "❌ Cancelled."; exit 0; }

# Get current user info
CURRENT_USER=$(whoami)
USER_HOME="$HOME"

log "Starting deep cleanup for user: $CURRENT_USER"
log "Home directory: $USER_HOME"

# ================================
# 1. Remove Android Studio Installations
# ================================
log "📱 [1/20] Removing Android Studio installations..."

# Common installation locations
ANDROID_STUDIO_LOCATIONS=(
    "$USER_HOME/android-studio"
    "$USER_HOME/.local/share/JetBrains/Toolbox/apps/AndroidStudio"
    "/opt/android-studio"
    "$USER_HOME/Applications/Android Studio.app"  # macOS style if copied
    "$USER_HOME/.local/share/applications/android-studio"
)

for location in "${ANDROID_STUDIO_LOCATIONS[@]}"; do
    safe_remove "$location" "Android Studio installation"
done

# ================================
# 2. Remove Android SDK and NDK
# ================================
log "📦 [2/20] Removing Android SDK and NDK..."

SDK_LOCATIONS=(
    "$USER_HOME/Android/Sdk"
    "$USER_HOME/android-sdk"
    "$USER_HOME/android-sdk-linux"
    "$USER_HOME/Library/Android/sdk"  # macOS style
    "$USER_HOME/.android-sdk"
    "$USER_HOME/android-ndk"
    "$USER_HOME/android-ndk-*"
)

for location in "${SDK_LOCATIONS[@]}"; do
    safe_remove "$location" "Android SDK/NDK"
done

# ================================
# 3. Remove AVD (Android Virtual Devices)
# ================================
log "📱 [3/20] Removing Android Virtual Devices..."

AVD_LOCATIONS=(
    "$USER_HOME/.android/avd"
    "$USER_HOME/.android/cache"
    "$USER_HOME/.android/build-cache"
    "$USER_HOME/.android/gradle"
    "$USER_HOME/Library/Android/avd"  # macOS style
)

for location in "${AVD_LOCATIONS[@]}"; do
    safe_remove "$location" "AVD files"
done

# ================================
# 4. Remove Gradle Files
# ================================
log "🔧 [4/20] Removing Gradle files and caches..."

GRADLE_LOCATIONS=(
    "$USER_HOME/.gradle"
    "$USER_HOME/gradle"
    "$USER_HOME/.gradle-wrapper"
)

for location in "${GRADLE_LOCATIONS[@]}"; do
    safe_remove "$location" "Gradle files"
done

# ================================
# 5. Remove IntelliJ IDEA Android Configs
# ================================
log "💡 [5/20] Removing IntelliJ IDEA Android configurations..."

INTELLIJ_LOCATIONS=(
    "$USER_HOME/.IntelliJIdea*/config/plugins/android"
    "$USER_HOME/.IntelliJIdea*/system/plugins-sandbox/plugins/android"
    "$USER_HOME/.cache/JetBrains/IntelliJIdea*/plugins/android"
    "$USER_HOME/.local/share/JetBrains/IntelliJIdea*/plugins/android"
)

for location in "${INTELLIJ_LOCATIONS[@]}"; do
    safe_remove "$location" "IntelliJ Android plugin"
done

# ================================
# 6. Remove Development Certificates
# ================================
log "🔐 [6/20] Removing development certificates and keystores..."

CERT_LOCATIONS=(
    "$USER_HOME/.android/debug.keystore"
    "$USER_HOME/.android/adbkey"
    "$USER_HOME/.android/adbkey.pub"
    "$USER_HOME/android-release-key.keystore"
    "$USER_HOME/my-release-key.keystore"
    "$USER_HOME/keystore.jks"
    "$USER_HOME/.android/androidtool.cfg"
)

for location in "${CERT_LOCATIONS[@]}"; do
    safe_remove "$location" "Development certificates"
done

# ================================
# 7. Remove Build Caches and Temporary Files
# ================================
log "🗂️ [7/20] Removing build caches and temporary files..."

# Remove build directories in common project locations
COMMON_PROJECT_DIRS=(
    "$USER_HOME/AndroidStudioProjects"
    "$USER_HOME/Projects"
    "$USER_HOME/workspace"
    "$USER_HOME/Documents"
    "$USER_HOME/Desktop"
)

for project_dir in "${COMMON_PROJECT_DIRS[@]}"; do
    if [[ -d "$project_dir" ]]; then
        log "Cleaning build files in $project_dir"
        find "$project_dir" -name "build" -type d -path "*/android/*" -exec rm -rf {} + 2>/dev/null || true
        find "$project_dir" -name ".gradle" -type d -exec rm -rf {} + 2>/dev/null || true
        find "$project_dir" -name "*.apk" -type f -exec rm -f {} + 2>/dev/null || true
        find "$project_dir" -name "*.aab" -type f -exec rm -f {} + 2>/dev/null || true
    fi
done

# ================================
# 8. Remove Flutter SDK
# ================================
log "🦋 [8/20] Removing Flutter SDK..."

FLUTTER_LOCATIONS=(
    "$USER_HOME/flutter"
    "$USER_HOME/development/flutter"
    "$USER_HOME/.flutter"
    "$USER_HOME/snap/flutter"
    "$USER_HOME/.pub-cache"
)

for location in "${FLUTTER_LOCATIONS[@]}"; do
    safe_remove "$location" "Flutter SDK"
done

# ================================
# 9. Remove Dart SDK
# ================================
log "🎯 [9/20] Removing Dart SDK..."

DART_LOCATIONS=(
    "$USER_HOME/dart-sdk"
    "$USER_HOME/.dart"
    "$USER_HOME/.dartServer"
)

for location in "${DART_LOCATIONS[@]}"; do
    safe_remove "$location" "Dart SDK"
done

# ================================
# 10. Remove Cordova/PhoneGap Files
# ================================
log "📱 [10/20] Removing Cordova/PhoneGap files..."

CORDOVA_LOCATIONS=(
    "$USER_HOME/.cordova"
    "$USER_HOME/.phonegap"
    "$USER_HOME/cordova"
)

for location in "${CORDOVA_LOCATIONS[@]}"; do
    safe_remove "$location" "Cordova/PhoneGap files"
done

# ================================
# 11. Remove React Native Caches
# ================================
log "⚛️ [11/20] Removing React Native caches..."

RN_LOCATIONS=(
    "$USER_HOME/.react-native-cli"
    "$USER_HOME/react-native"
    "$USER_HOME/.metro"
)

for location in "${RN_LOCATIONS[@]}"; do
    safe_remove "$location" "React Native files"
done

# ================================
# 12. Remove Desktop Entries and Menu Items
# ================================
log "🖥️ [12/20] Removing desktop entries..."

DESKTOP_ENTRIES=(
    "$USER_HOME/.local/share/applications/jetbrains-android-studio.desktop"
    "$USER_HOME/.local/share/applications/android-studio.desktop"
    "$USER_HOME/Desktop/Android Studio.desktop"
    "/usr/share/applications/android-studio.desktop"
)

for entry in "${DESKTOP_ENTRIES[@]}"; do
    safe_remove "$entry" "Desktop entry"
done

# ================================
# 13. Remove Shell Configuration
# ================================
log "🐚 [13/20] Cleaning shell configurations..."

SHELL_CONFIGS=(
    "$USER_HOME/.bashrc"
    "$USER_HOME/.zshrc"
    "$USER_HOME/.profile"
    "$USER_HOME/.bash_profile"
)

for config in "${SHELL_CONFIGS[@]}"; do
    if [[ -f "$config" ]]; then
        log "Cleaning Android paths from $config"
        # Create backup
        cp "$config" "${config}.backup.$(date +%Y%m%d_%H%M%S)"
        # Remove Android-related exports
        sed -i '/ANDROID_HOME/d; /ANDROID_SDK_ROOT/d; /android-sdk/d; /android-studio/d; /flutter/d; /dart/d' "$config"
        success "Cleaned $config (backup created)"
    fi
done

# ================================
# 14. Remove Emulator Files
# ================================
log "🎮 [14/20] Removing emulator files..."

EMULATOR_LOCATIONS=(
    "$USER_HOME/.android/emulator"
    "$USER_HOME/.android/console-auth-token"
    "$USER_HOME/.emulator_console_auth_token"
)

for location in "${EMULATOR_LOCATIONS[@]}"; do
    safe_remove "$location" "Emulator files"
done

# ================================
# 15. Remove JetBrains Toolbox Android Studio
# ================================
log "🧰 [15/20] Removing JetBrains Toolbox Android Studio..."

if [[ -d "$USER_HOME/.local/share/JetBrains/Toolbox" ]]; then
    log "Cleaning JetBrains Toolbox Android Studio installations"
    find "$USER_HOME/.local/share/JetBrains/Toolbox" -name "*Android*" -type d -exec rm -rf {} + 2>/dev/null || true
fi

# ================================
# 16. Remove Snap Packages
# ================================
log "📦 [16/20] Removing snap packages..."

if command -v snap &> /dev/null; then
    ANDROID_SNAPS=$(snap list 2>/dev/null | grep -E "(android|flutter)" | awk '{print $1}' || true)
    if [[ -n "$ANDROID_SNAPS" ]]; then
        echo "$ANDROID_SNAPS" | while read -r snap_name; do
            log "Removing snap package: $snap_name"
            snap remove "$snap_name" 2>/dev/null || true
        done
    fi
fi

# ================================
# 17. Remove APT Packages
# ================================
log "📦 [17/20] Removing APT packages..."

if command -v apt &> /dev/null; then
    APT_PACKAGES=$(dpkg -l 2>/dev/null | grep -E "(android|flutter)" | awk '{print $2}' || true)
    if [[ -n "$APT_PACKAGES" ]] && [[ "$EUID" -eq 0 ]]; then
        echo "$APT_PACKAGES" | while read -r package; do
            log "Removing APT package: $package"
            apt remove --purge -y "$package" 2>/dev/null || true
        done
    fi
fi

# ================================
# 18. Clean Cache Directories
# ================================
log "🧹 [18/20] Cleaning cache directories..."

CACHE_DIRS=(
    "$USER_HOME/.cache/android-studio"
    "$USER_HOME/.cache/JetBrains/AndroidStudio*"
    "$USER_HOME/.cache/gradle"
    "$USER_HOME/.cache/flutter"
    "$USER_HOME/.cache/dart"
)

for cache_dir in "${CACHE_DIRS[@]}"; do
    safe_remove "$cache_dir" "Cache directory"
done

# ================================
# 19. Remove Temporary Files
# ================================
log "🗑️ [19/20] Removing temporary files..."

# Find and remove temporary Android files
find /tmp -name "*android*" -user "$CURRENT_USER" -exec rm -rf {} + 2>/dev/null || true
find /tmp -name "*studio*" -user "$CURRENT_USER" -exec rm -rf {} + 2>/dev/null || true
find /tmp -name "*.apk" -user "$CURRENT_USER" -exec rm -f {} + 2>/dev/null || true

# ================================
# 20. Final Cleanup
# ================================
log "✨ [20/20] Final cleanup..."

# Update desktop database
if command -v update-desktop-database &> /dev/null; then
    update-desktop-database "$USER_HOME/.local/share/applications" 2>/dev/null || true
fi

# Clear bash history of Android commands
if [[ -f "$USER_HOME/.bash_history" ]]; then
    log "Cleaning Android commands from bash history"
    cp "$USER_HOME/.bash_history" "$USER_HOME/.bash_history.backup.$(date +%Y%m%d_%H%M%S)"
    sed -i '/android/Id; /studio/Id; /gradle/Id; /flutter/Id; /dart/Id; /adb/Id; /fastboot/Id' "$USER_HOME/.bash_history"
fi

echo ""
success "🎉 Android Studio Deep Cleanup Complete!"
echo ""
log "📊 Summary of cleanup:"
log "   ✅ Android Studio installations removed"
log "   ✅ SDK and NDK removed"
log "   ✅ Virtual devices removed"
log "   ✅ Gradle files removed"
log "   ✅ Development certificates removed"
log "   ✅ Build caches cleared"
log "   ✅ Flutter/Dart SDKs removed"
log "   ✅ Desktop entries removed"
log "   ✅ Shell configurations cleaned"
log "   ✅ Cache directories cleared"
echo ""
warning "Backups of modified config files were created with timestamp suffixes"
warning "Please restart your terminal or source your shell config files"
echo ""
log "🔄 Recommended next steps:"
log "   1. Restart your terminal"
log "   2. Log out and log back in (to clear environment variables)"
log "   3. Check that 'which android-studio' returns nothing"
log "   4. Verify no Android Studio processes are running"
echo ""
read -p "🔍 Do you want to see a summary of remaining Android-related files? (y/N): " show_remaining
if [[ "$show_remaining" =~ ^[Yy]$ ]]; then
    log "Searching for any remaining Android-related files..."
    find "$USER_HOME" -iname "*android*" -o -iname "*studio*" -o -iname "*gradle*" 2>/dev/null | head -20
    log "If any important files are shown above, they were preserved for safety"
fi

success "Deep cleanup completed successfully! 🎉"
