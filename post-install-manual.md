## Fix screen tearing / Vertical Sync
A. [**Nouveau driver** - use Picom compositor config](https://wiki.archlinux.org/title/Nouveau#Vertical_Sync)  

   ```bash
   sudo pacman -Syu picom
   echo -e 'picom -b --unredir-if-possible --backend xr_glx_hybrid --vsync --use-damage --glx-no-stencil' >> ~/.profile
   ```
B. Check if tearing exists with proprietary **Nvidia driver** (AUR)

# Sound

  * alsa the kernel sound system works out of the box (just needs to be unmuted) - PulseAudio sound server could be installed for additional features
  
    ```bash
    sudo pamcan -Syu alsa-utils
    
    amixer set Master unmute
    amixer set Headphone unmute
    amixer set Speaker mute
    ```
    
  * Use alasmixer to manually increase volume of master, headphone & pcm, set speaker to 0 and enable auto mute
  * Settings should be saved but to make sure they're persistent try:

    ```bash
    # A - Save state to a file then restore that file on startup
    sudo alsactl store # saves mixer settings to /var/lib/alsa/asound.state
    sudo alsactl --file ~/.config/asound.state store # save state to file
    echo -e 'alsactl --file ~/.config/asound.state restore' >> ~/.bashrc
    
    # B (untested) - Add to .profile or .bashrc (?)
    amixer -q -M set Master 33%
    amixer -q -M set Headphone 50%
    amixer -q -M set Speaker 0
    amixer -q -M set PCM 50%
    ```

  * Adjust volume from CLI:

    ```bash
    amixer set -q Master 1+
    ```
    > -q  
    > Quiet mode. Do not show results of changes
    > -R  
    > Use the raw value for evaluating the percentage representation. This is the default mode.  
    > -M  
    > Use the mapped volume for evaluating the percentage representation like alsamixer, to be more natural for human ear.  
    
  * Read current volume (to not allow raising above a cap)  
  
    ```bash
    amixer get Master | grep Mono: Playback
    ```

# Brightness

  * Set screen brightness from CLI
  
    ```bash
    sudo tee /sys/class/backlight/nv_backlight/brightness <<< 50
    ```

  * Create udev rule then add user to video group to not require password
  
    ```bash
    /etc/udev/rules.d/backlight.rules
    RUN+="/bin/chgrp video /sys/class/backlight/nv_backlight/brightness"
    RUN+="/bin/chmod g+w /sys/class/backlight/nv_backlight/brightness"

    sudo usermod -aG video vanderlyle
    ```
  * Read current value with `cat /sys/class/backlight/nv_backlight/brightness` before applying adjustment to not allow 0 brightness


