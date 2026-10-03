#!/bin/bash
# ====================================================
# 🦊 Shirakami Master AIO Script v8.6 (Gentoo OpenRC + Guru + Verbose Emerge)
# ====================================================

echo "=========================================="
echo " 🦊 [Gentoo OpenRC] Starting Setup with Verbose Emerge... :p"
echo "=========================================="

# ฟังก์ชันรันคำสั่งโดยเช็คว่ามี sudo ไหม ถ้าไม่มีให้รันตรงๆ
run_privileged() {
    if command -v sudo &> /dev/null; then
        sudo "$@"
    else
        "$@"
    fi
}

# ----------------------------------------------------
# 1. OpenRC Service Masking (ปิดบริการ maked ถาวร)
# ----------------------------------------------------
echo "❌ [1/10] OpenRC Service Masking for 'maked'..."
run_privileged pkill -9 -f maked 2>/dev/null || true
run_privileged rc-service maked stop 2>/dev/null || true
run_privileged rc-update del maked default 2>/dev/null || true
run_privileged rc-update del maked boot 2>/dev/null || true

if [ -f /etc/init.d/maked ]; then
    run_privileged rm -f /etc/init.d/maked
    run_privileged ln -s /dev/null /etc/init.d/maked
fi
run_privileged chmod 000 /usr/bin/maked 2>/dev/null || true

run_privileged rm -rf /var/tmp/flagged /tmp/flagged ~/.flagged 2>/dev/null || true
run_privileged touch /tmp/flagged ~/.flagged 2>/dev/null || true
run_privileged chattr +i /tmp/flagged ~/.flagged 2>/dev/null || true

# ----------------------------------------------------
# 1.5. Enable Guru Overlay (ดึงคลัง ebuilds เพิ่มเติม)
# ----------------------------------------------------
echo "🌐 [1.5/10] Enabling & Syncing Guru Repository..."
run_privileged emerge --noreplace dev-vcs/git app-eselect/eselect-repository
run_privileged eselect repository enable guru
run_privileged emaint sync -r guru

# ----------------------------------------------------
# 2. ติดตั้ง Hyprland, Caelestia, Hidamari & Dependencies (โชว์การติดตั้งชัดๆ)
# ----------------------------------------------------
echo "🧹 [2/10] Installing Hyprland, Caelestia & Hidamari Live Wallpaper..."
run_privileged emerge --deselect gui-apps/fuzzel gui-wm/niri 2>/dev/null || true

run_privileged emerge --noreplace \
    gui-wm/hyprland \
    gui-apps/caelestia-shell \
    media-gfx/hidamari \
    gui-apps/mpvpaper \
    gui-apps/waypaper \
    media-video/ffmpeg \
    media-fonts/noto-emoji \
    media-fonts/noto-thai \
    media-fonts/inter

# ----------------------------------------------------
# 3. ติดตั้ง Packages สำคัญอื่นๆ (เปิดให้เห็นการโหลด + แก้ชื่อ android-tools)
# ----------------------------------------------------
echo "📦 [3/10] Installing Audio, Gaming & Utility Packages..."
export USE="wayland vulkan opengl adb vaapi vdpau bluetooth pipewire staging openrc"

run_privileged emerge --noreplace \
    dev-util/android-tools \
    media-video/vlc \
    media-sound/pipewire \
    media-sound/wireplumber \
    app-emulation/vmware-workstation \
    games-emulation/ppsspp \
    games-emulation/dolphin-emu \
    kde-apps/dolphin \
    gui-apps/hyprshot \
    games-action/heroic-games-launcher-bin \
    games-util/steam-meta \
    x11-misc/winboat \
    app-containers/waydroid \
    x11-drivers/xf86-video-amdgpu \
    media-libs/mesa \
    app-misc/fastfetch \
    app-misc/neofetch \
    app-emulation/wine-staging \
    sys-power/tlp

# ----------------------------------------------------
# 4. Caelestia Lock Screen Generator
# ----------------------------------------------------
echo "🎨 [4/10] Setting up Caelestia Lock Screen Preset Generator..."
mkdir -p ~/.config/caelestia/scripts/

cat << 'LOCK_SCRIPT' > ~/.config/caelestia/scripts/caelestia-lock-preset
#!/bin/bash
STYLE=${1:-1}
CORNER=${2:-2}
SHOW_STATS=${3:-true}
CLOCK_FMT=${4:-"hh:mm | dddd dd MMMM"}

case $CORNER in
    1) POS_X="20"; POS_Y="20" ;;
    2) POS_X="1600"; POS_Y="20" ;;
    3) POS_X="20"; POS_Y="950" ;;
    4) POS_X="1600"; POS_Y="950" ;;
    *) POS_X="1600"; POS_Y="20" ;;
esac

cat << QML > ~/.config/caelestia/lockscreen.qml
import QtQuick 2.15
import Caelestia.Shell 1.0

Item {
    id: lockRoot
    width: 1920
    height: 1080

    property string fontThai: "Noto Sans Thai"
    property string fontEn: "Inter"

    Item {
        x: $POS_X
        y: $POS_Y
        visible: $SHOW_STATS
        Text {
            text: "🦊 CPU: " + System.cpuUsage + "% | RAM: " + System.ramUsage + "% ✨"
            font.family: fontEn
            font.pixelSize: 16
            color: "#FFFFFF"
        }
    }

    Text {
        anchors.centerIn: parent
        text: Qt.formatDateTime(new Date(), "$CLOCK_FMT")
        font.family: fontThai
        font.pixelSize: 64
        color: "#FDFDFD"
    }
}
QML
LOCK_SCRIPT

chmod +x ~/.config/caelestia/scripts/caelestia-lock-preset

# ----------------------------------------------------
# 5. Waydroid Auto ADB Script
# ----------------------------------------------------
echo "🤖 [5/10] Setting up Waydroid Auto-ADB Script..."
run_privileged waydroid init -s GAPPS -f https://mota.waydro.id/13 2>/dev/null || true
run_privileged usermod -aG adb $USER 2>/dev/null || true

cat << 'ADB_SCRIPT' | run_privileged tee /usr/local/bin/waydroid-adb-auto > /dev/null
#!/bin/bash
sleep 3
WAYDROID_IP=$(waydroid status 2>/dev/null | grep "IP:" | awk '{print $2}')
if [ -z "$WAYDROID_IP" ]; then
    WAYDROID_IP="192.168.240.112"
fi
adb connect $WAYDROID_IP:5555 2>/dev/null || true
ADB_SCRIPT

run_privileged chmod +x /usr/local/bin/waydroid-adb-auto

# ----------------------------------------------------
# 6. Gaming System Optimisations (sysctl)
# ----------------------------------------------------
echo "⚡ [6/10] Applying Gaming Tweaks..."
cat << 'SYSCTL' | run_privileged tee /etc/sysctl.d/99-gaming-optimiser.conf > /dev/null
vm.max_map_count = 2147483642
vm.swappiness = 10
fs.file-max = 2097152
kernel.sched_autogroup_enabled = 1
SYSCTL
run_privileged sysctl --system 2>/dev/null || true

# ----------------------------------------------------
# 7. Hyprland Config
# ----------------------------------------------------
echo "🎨 [7/10] Configuring Hyprland & Autostarting Hidamari..."
mkdir -p ~/.config/hypr/ ~/wallpapers ~/Pictures/Screenshots

cat << 'HYPR' > ~/.config/hypr/hyprland.conf
monitor=,preferred,auto,1

env = DRI_PRIME,1
env = __GLX_VENDOR_LIBRARY_NAME,amdgpu
env = WSA_ENABLE_DGPU,1

$mainMod = SUPER

bind = $mainMod, R, exec, caelestia shell drawers toggle launcher
bind = $mainMod, E, exec, dolphin
bind = $mainMod, SPACE, exec, hyprctl switchxkblayout current next
bind = $mainMod, W, exec, hidamari

bind = , Print, exec, hyprshot -m region --clipboard-only
bind = $mainMod, Print, exec, hyprshot -m window -o ~/Pictures/Screenshots
bind = $mainMod SHIFT, S, exec, hyprshot -m region -o ~/Pictures/Screenshots

input {
    kb_layout = us,th
    kb_options = grp:win_space_toggle
}

exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = caelestia shell
exec-once = hidamari --autostart
exec-once = /usr/local/bin/waydroid-adb-auto
HYPR

# ----------------------------------------------------
# 8. ~/.bashrc Integration
# ----------------------------------------------------
echo "⚙ [8/10] Configuring Bash Commands & Default Fastfetch..."
cat << 'BASH' >> ~/.bashrc

[ -f ./bash ] && source ./bash

set-lock() {
    ~/.config/caelestia/scripts/caelestia-lock-preset "$1" "$2" "$3" "$4"
}

df1() {
    /usr/local/bin/waydroid-adb-auto
    adb shell svc power stayon true 2>/dev/null || true
    hyprctl dispatch dpms on 2>/dev/null || true
    trap 'echo -e "\n🛑 [df1] Stopped by Ctrl+C! :p"; return' INT
    while true; do
        adb shell input tap 960 920
        sleep 5
        adb shell input tap 110 115
        sleep 0.1
    done
}

upd() {
    echo "🔄 Updating Gentoo System & Applications..."
    if command -v sudo &> /dev/null; then
        sudo emerge --sync
        sudo emerge --ask=n --verbose --update --deep --newuse @world
        sudo emerge --depclean
    else
        emerge --sync
        emerge --ask=n --verbose --update --deep --newuse @world
        emerge --depclean
    fi
    echo "✅ System Update Finished! :3"
}

export DRI_PRIME=1

if command -v fastfetch &> /dev/null; then
    fastfetch
elif command -v neofetch &> /dev/null; then
    neofetch
fi
BASH

# ----------------------------------------------------
# 9. Enable OpenRC Services
# ----------------------------------------------------
echo "🚀 [9/10] Enabling OpenRC Services..."
run_privileged rc-update add dbus default 2>/dev/null || true
run_privileged rc-update add NetworkManager default 2>/dev/null || true
run_privileged rc-update add waydroid-container default 2>/dev/null || true
run_privileged rc-update add tlp default 2>/dev/null || true

run_privileged rc-service dbus start 2>/dev/null || true
run_privileged rc-service NetworkManager start 2>/dev/null || true
run_privileged rc-service waydroid-container start 2>/dev/null || true
run_privileged rc-service tlp start 2>/dev/null || true

# ----------------------------------------------------
# 10. Finish
# ----------------------------------------------------
echo "=========================================="
echo " 🎉 SHIRAKAMI MASTER AIO READY! :3"
echo "=========================================="
