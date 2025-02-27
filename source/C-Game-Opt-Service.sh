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
    if [[ -z "$GAME" || ! -f "$GAME" ]]; then
        ui_print "- GAME file not found or not specified."
        return 1
    fi

    if [[ -z "$FPS" ]]; then
        ui_print "- FPS value is not specified."
        return 1
    fi

    while IFS= read -r game; do
        [[ -z "$game" ]] && continue

        if cmd game mode performance "$game" set --fps "$FPS"; then
            ui_print "- Successfully set Game Mode for $game"
        else
            ui_print "- Failed to set Game Mode for $game"
        fi

    done < "$GAME"
}
   
miui_boost_feature() {
    if [[ "$POWER_MIUI" == "middle" ]]; then
        setprop debug.power.monitor_tools false
        
        write system POWER_BALANCED_MODE_OPEN 0
        write system POWER_PERFORMANCE_MODE_OPEN 1
        write system POWER_SAVE_MODE_OPEN 0
        write system power_mode middle
        write system POWER_SAVE_PRE_HIDE_MODE performance
        write system POWER_SAVE_PRE_SYNCHRONIZE_ENABLE 1
    else
        ui_print "- POWER_MIUI value is invalid or not set"
        return 1
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
}
  
final_optimization() {
# Enable performance tuning & hardware acceleration
  setprop debug.performance.tuning 1
  setprop debug.sf.hw 1
  setprop debug.egl.hw 1

# Optimize CPU power management
  CPU_OPTS=""
  for i in $(seq 1 8); do
     CPU_OPTS="${CPU_OPTS}power_check_max_cpu_${i}=0,"
  done
  write_sys global activity_manager_constants "${CPU_OPTS%,}"

# Disable logging & set high priority
  write global activity_starts_logging_enabled 0
  write secure high_priority 1

# Clear cache & disable unnecessary statistics
  cmd stats clear-puller-cache
  cmd display ab-logging-disable
  cmd display dwb-logging-disable
  cmd looper_stats disable
  am memory-factor set CRITICAL

# Adjust refresh rate preferences
  cmd display set-match-content-frame-rate-pref 2

# Disable Adaptive Power Saver & enable performance mode
  cmd power set-adaptive-power-saver-enabled false
  cmd power set-fixed-performance-mode-enabled true

# Disable thermal limitations
  cmd thermalservice override-status 0

# Run simpleperf for lighter logging
  simpleperf --log fatal --log-to-android-buffer 6
  
# Adjust animation
  write global window_animation_scale 0.8
  write global transition_animation_scale 0.8
  write global animator_duration_scale 0.8
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