# แก้ขั้นตอนที่ 2
emerge --noreplace \
    gui-wm/hyprland \
    gui-apps/caelestia-shell \
    media-gfx/hidamari \
    gui-apps/mpvpaper \
    gui-apps/waypaper \
    media-video/ffmpeg \
    media-fonts/noto-emoji \
    media-fonts/noto-thai \
    media-fonts/inter

# แก้ขั้นตอนที่ 3
emerge --ask \
    sys-apps/adb \
    net-wireless/android-tools \
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
