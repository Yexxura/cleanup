#!/bin/bash

# Script untuk menjaga Ubuntu desktop online 24 jam
# Pastikan jalankan dengan sudo untuk beberapa pengaturan

echo "=== Ubuntu 24/7 Online Setup ==="

# 1. Nonaktifkan suspend/sleep mode
echo "Menonaktifkan suspend dan sleep mode..."

# Nonaktifkan suspend saat idle
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'

# Nonaktifkan screen blanking
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
gsettings set org.gnome.desktop.session idle-delay 0

# 2. Nonaktifkan hibernasi dan suspend via systemd
echo "Menonaktifkan hibernasi dan suspend di systemd..."
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target

# 3. Konfigurasi power management
echo "Mengkonfigurasi power management..."
sudo bash -c 'cat > /etc/systemd/logind.conf << EOF
[Login]
HandlePowerKey=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
IdleAction=ignore
IdleActionSec=0
EOF'

# 4. Nonaktifkan DPMS (Display Power Management Signaling)
echo "Menonaktifkan DPMS..."
xset -dpms
xset s off
xset s noblank

# Tambahkan ke .bashrc untuk permanen
echo "xset -dpms" >> ~/.bashrc
echo "xset s off" >> ~/.bashrc
echo "xset s noblank" >> ~/.bashrc

# 5. Install dan konfigurasi caffeine (opsional)
echo "Menginstall caffeine untuk mencegah sleep..."
sudo apt update
sudo apt install caffeine -y

# 6. Buat script untuk menjaga koneksi network
echo "Membuat script network keepalive..."
sudo bash -c 'cat > /usr/local/bin/network-keepalive.sh << EOF
#!/bin/bash
# Script untuk menjaga koneksi network tetap aktif

while true; do
    # Ping Google DNS setiap 30 detik
    ping -c 1 8.8.8.8 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "$(date): Network is alive"
    else
        echo "$(date): Network issue detected, attempting to restart..."
        sudo systemctl restart NetworkManager
    fi
    sleep 30
done
EOF'

sudo chmod +x /usr/local/bin/network-keepalive.sh

# 7. Buat systemd service untuk network keepalive
echo "Membuat systemd service untuk network keepalive..."
sudo bash -c 'cat > /etc/systemd/system/network-keepalive.service << EOF
[Unit]
Description=Network Keepalive Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/network-keepalive.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'

# 8. Aktifkan dan jalankan service
sudo systemctl daemon-reload
sudo systemctl enable network-keepalive.service
sudo systemctl start network-keepalive.service

# 9. Konfigurasi cron job untuk restart network setiap jam (opsional)
echo "Menambahkan cron job untuk maintenance network..."
(crontab -l 2>/dev/null; echo "0 */1 * * * /bin/ping -c 1 8.8.8.8 || sudo systemctl restart NetworkManager") | crontab -

# 10. Nonaktifkan auto-update yang bisa menyebabkan restart
echo "Mengkonfigurasi auto-update..."
sudo bash -c 'cat > /etc/apt/apt.conf.d/20auto-upgrades << EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "0";
EOF'

# 11. Reload konfigurasi tanpa restart
echo "Memuat ulang konfigurasi tanpa restart sistem..."
sudo systemctl daemon-reload
sudo systemctl reload systemd-logind

# Terapkan pengaturan display langsung
xset -dpms
xset s off
xset s noblank

# 12. Buat script untuk mencegah sleep secara real-time
echo "Membuat script anti-sleep real-time..."
sudo bash -c 'cat > /usr/local/bin/anti-sleep.sh << EOF
#!/bin/bash
# Script untuk mencegah sistem sleep secara real-time

while true; do
    # Simulasi aktivitas mouse
    xdotool mousemove_relative 1 1
    sleep 1
    xdotool mousemove_relative -- -1 -1
    
    # Prevent screen lock
    xset -dpms
    xset s off
    xset s noblank
    
    # Simulasi keystroke (Scroll Lock on/off - tidak terlihat user)
    xdotool key Scroll_Lock
    sleep 1
    xdotool key Scroll_Lock
    
    sleep 300  # Jalankan setiap 5 menit
done
EOF'

sudo chmod +x /usr/local/bin/anti-sleep.sh

# 13. Install xdotool jika belum ada
echo "Menginstall xdotool..."
sudo apt install xdotool -y

# 14. Buat systemd service untuk anti-sleep
echo "Membuat service anti-sleep..."
sudo bash -c 'cat > /etc/systemd/system/anti-sleep.service << EOF
[Unit]
Description=Anti Sleep Service
After=graphical-session.target

[Service]
Type=simple
User=$(whoami)
Environment=DISPLAY=:0
ExecStart=/usr/local/bin/anti-sleep.sh
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF'

# 15. Aktifkan service anti-sleep
sudo systemctl daemon-reload
sudo systemctl enable anti-sleep.service
sudo systemctl start anti-sleep.service

# 16. Disable swap untuk mencegah freeze sistem
echo "Menonaktifkan swap untuk performa 24/7..."
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# 17. Optimasi kernel untuk uptime maksimal
echo "Mengoptimasi kernel parameters..."
sudo bash -c 'cat >> /etc/sysctl.conf << EOF

# Optimasi untuk uptime 24/7
vm.swappiness=1
vm.dirty_ratio=15
vm.dirty_background_ratio=5
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 65536 134217728
net.ipv4.tcp_wmem=4096 65536 134217728
EOF'

# Terapkan sysctl tanpa restart
sudo sysctl -p

# 18. Buat script monitoring uptime
echo "Membuat script monitoring uptime..."
sudo bash -c 'cat > /usr/local/bin/uptime-monitor.sh << EOF
#!/bin/bash
# Monitor uptime dan catat ke log

LOGFILE="/var/log/uptime-monitor.log"

while true; do
    UPTIME=$(uptime -p)
    TIMESTAMP=$(date)
    echo "[$TIMESTAMP] System uptime: $UPTIME" >> $LOGFILE
    
    # Cek load average
    LOAD=$(uptime | awk -F"load average:" "{print \$2}")
    echo "[$TIMESTAMP] Load average:$LOAD" >> $LOGFILE
    
    # Cek memory usage
    MEM=$(free -h | grep "Mem:" | awk "{print \"Used: \"\$3\" / \"\$2}")
    echo "[$TIMESTAMP] Memory $MEM" >> $LOGFILE
    
    sleep 3600  # Log setiap jam
done
EOF'

sudo chmod +x /usr/local/bin/uptime-monitor.sh

# 19. Service untuk uptime monitoring
sudo bash -c 'cat > /etc/systemd/system/uptime-monitor.service << EOF
[Unit]
Description=Uptime Monitor Service
After=multi-user.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/uptime-monitor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF'

sudo systemctl enable uptime-monitor.service
sudo systemctl start uptime-monitor.service

# 20. Jalankan semua konfigurasi langsung tanpa restart
echo "Menerapkan konfigurasi secara langsung..."

# Start caffeine jika tersedia
if command -v caffeine &> /dev/null; then
    caffeine &
fi

# Terapkan setting GNOME langsung
if command -v gsettings &> /dev/null; then
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
    gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
    gsettings set org.gnome.desktop.session idle-delay 0
fi

echo ""
echo "=== Setup Selesai - SISTEM SUDAH AKTIF 24/7 ==="
echo "Ubuntu desktop sekarang berjalan 24 jam TANPA PERLU RESTART"
echo ""
echo "Yang telah dikonfigurasi dan aktif:"
echo "✓ Sleep/suspend mode dinonaktifkan"
echo "✓ Screen saver dinonaktifkan"
echo "✓ Power management dinonaktifkan"
echo "✓ Network keepalive service aktif"
echo "✓ Anti-sleep service berjalan"
echo "✓ Uptime monitoring aktif"
echo "✓ Sistem optimasi untuk 24/7"
echo "✓ Swap dinonaktifkan untuk stabilitas"
echo ""
echo "Status layanan:"
echo "- Network keepalive: $(sudo systemctl is-active network-keepalive)"
echo "- Anti-sleep: $(sudo systemctl is-active anti-sleep)"
echo "- Uptime monitor: $(sudo systemctl is-active uptime-monitor)"
echo ""
echo "Monitoring:"
echo "- Status: sudo systemctl status anti-sleep"
echo "- Log uptime: sudo tail -f /var/log/uptime-monitor.log"
echo "- Current uptime: $(uptime -p)"
echo ""
echo "🟢 SISTEM SEKARANG ONLINE 24/7 TANPA RESTART!"
