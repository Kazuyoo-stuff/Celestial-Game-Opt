#!/system/bin/sh
#
# Celestial-Game-Opt by the kazuyoo
# Created NR By @KazuyooOpenSources
# open-source loving GL-DP and all contributors;
# System Properties Which has been adjusted so that the app runs more perfectly and is responsive.
#

# ----------------- HELPER FUNCTIONS -----------------
source /storage/emulated/0/Kazu/META-INF/com/google/android/update-binary

POWER_MIUI=$(settings get system power_mode)

send_notification() {
    # Notify user of optimization completion
    cmd notification post -S bigtext -t 'Celestial-Game-Opt 🪽' 'tag' 'Status : Optimization Completed!' >/dev/null 2>&1
}

# ----------------- OPTIMIZATION SECTIONS -----------------
game_manager() {
    if [ -z "$GAME" ] || [ ! -f "$GAME" ]; then
        ui_print "File GAME tidak ditemukan atau tidak ditentukan."
        return 1
    fi

    while IFS= read -r game; do
        [ -z "$game" ] && continue

        cmd game mode performance "$game" set --fps "$FPS"
        
    done < "$GAME"
}
   
miui_boost_feature() {
    if [[ $POWER_MIUI = "middle" ]]; then
       setprop debug.power.monitor_tools false
       write system POWER_BALANCED_MODE_OPEN 0
       write system POWER_PERFORMANCE_MODE_OPEN 1
       write system POWER_SAVE_MODE_OPEN 0
       write system power_mode middle
       write system POWER_SAVE_PRE_HIDE_MODE performance
       write system POWER_SAVE_PRE_SYNCHRONIZE_ENABLE 1
    else
        ui_print "[WARN] ERRORS!"
    fi
}

bypass_refresh_rate() {
# Get the device brand
  BBK_BRANDS="oppo vivo oneplus realme iqoo"
  BRAND=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]')

# Get FPS value from system
  FPS=$(dumpsys display | grep -oE 'fps=[0-9]+' | awk -F '=' '{print $2}' | head -n 1)

# If the device is BBK, make sure the value is between 1-4
    if echo "$BBK_BRANDS" | grep -wq "$BRAND"; then
        if [ "$FPS" -le 1 ]; then
            FPS=1
        elif [ "$FPS" -le 2 ]; then
            FPS=2
        elif [ "$FPS" -le 3 ]; then
            FPS=3
        else
            FPS=4
        fi
    fi

# Set refresh rate
  settings put system peak_refresh_rate "$FPS"
  settings put system user_refresh_rate "$FPS"
  settings put system max_refresh_rate "$FPS"
  settings put system min_refresh_rate "$FPS"
  ui_print "set fps = $FPS"
}
  
final_optimization() {
    setprop debug.performance.tuning 1
    setprop debug.sf.hw 1
    setprop debug.egl.hw 1
    write global activity_manager_constants "power_check_max_cpu_1=0,power_check_max_cpu_2=0,power_check_max_cpu_3=0,power_check_max_cpu_4=0,power_check_max_cpu_5=0,power_check_max_cpu_6=0,power_check_max_cpu_7=0,power_check_max_cpu_8=0"
    write global activity_starts_logging_enabled 0
    write secure high_priority 1
    cmd stats clear-puller-cache
    cmd display ab-logging-disable
    cmd display dwb-logging-disable
    cmd display set-match-content-frame-rate-pref 2
    logcat -c --wrap
    simpleperf --log fatal --log-to-android-buffer 0
    cmd activity clear-watch-heap -a
    cmd looper_stats disable
    am memory-factor set CRITICAL
    cmd power set-adaptive-power-saver-enabled false
    cmd power set-fixed-performance-mode-enabled true
    cmd thermalservice override-status 0
}
  
# ----------------- MAIN EXECUTION -----------------
main() {
    game_manager
    miui_boost_feature
    bypass_refresh_rate
    final_optimization
}

# Main Execution & Exit script successfully
 sync && main && send_notification