#!/system/bin/sh
#
# Celestial-Game-Opt by the kazuyoo
# Created NR By @KazuyooOpenSources
# open-source loving GL-DP and all contributors;
# System Properties Which has been adjusted so that the app runs more perfectly and is responsive.
#

# ----------------- HELPER FUNCTIONS -----------------
source /storage/emulated/0/Kazu/META-INF/com/google/android/update-binary

# Variable
  POWER_MIUI=$(settings get system power_mode)
  CPU_OPTS=""
  GAME_LIST=$(cmd package list packages | grep -E "$GAME" | cut -f 2 -d ":")
  GAME_LIST=""

# ----------------- OPTIMIZATION SECTIONS -----------------
game_manager() {
# Get a list of installed game packages based on game list
    while IFS= read -r game; do
        [[ -z "$game" ]] && continue
            package=$(cmd package list packages | grep -E "$game" | cut -f 2 -d ":")
        if [[ -n "$package" ]]; then
            GAME_LIST+="$package "
        fi
    done <<< "$GAME"

# Loop each package and set Game Mode and Overlay
    for package in $GAME_LIST; do
        if cmd game mode performance "$package" set --fps "$FPS"; then
            if cmd device_config put game_overlay "$package" mode=2,downscaleFactor=0.9:mode=3,downscaleFactor=0.7; then
                ui_print "- Successfully set Game Mode for $package"
            else
                ui_print "- Failed to apply overlay settings for $package"
            fi
        else
            ui_print "- Failed to set Game Mode for $package"
        fi
    done
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
  write system peak_refresh_rate "$FPS"
  write system user_refresh_rate "$FPS"
  write system max_refresh_rate "$FPS"
  write system min_refresh_rate "$FPS"
}
  
final_optimization() {
# Enable performance tuning & hardware acceleration
  setprop debug.performance.tuning 1
  setprop debug.sf.hw 1
  setprop debug.egl.hw 1
  
# cpu cluster & powerhint configuration (@reljawa)
  setprop debug.cluster_little-set_his_speed $(cat /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_min_freq)
  setprop debug.cluster_big-set_his_speed $(cat /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_max_freq)
  setprop debug.powehint.cluster_little-set_his_speed $(cat /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_min_freq)
  setprop debug.powehint.cluster_big-set_his_speed $(cat /sys/devices/system/cpu/cpu1/cpufreq/cpuinfo_max_freq)

# Optimize CPU power management
  for i in $(seq 1 8); do
     CPU_OPTS="${CPU_OPTS}power_check_max_cpu_${i}=0,"
  done
  write global activity_manager_constants "${CPU_OPTS%,}"

# Disable logging & set high priority
  write global activity_starts_logging_enabled 0
  write secure high_priority 1

# Clear cache & disable unnecessary statistics
  cmd stats clear-puller-cache
  cmd activity clear-debug-app
  cmd activity clear-watch-heap -a
  cmd stats print-logs 0 # <- root required
  cmd display ab-logging-disable
  cmd display dwb-logging-disable
  cmd display dmd-logging-disable
  cmd looper_stats disable
  
# Overrides memory pressure factor
  am memory-factor set CRITICAL
 
# reset throttling on application shortcuts
  cmd shortcut reset-throttling --user 0
  cmd shortcut reset-all-throttling

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
  
# Disable app standby ( battery usage may increase )
  write global app_standby_enabled 0
}
  
# ----------------- MAIN EXECUTION -----------------
main() {
    game_manager
    miui_boost_feature
    bypass_refresh_rate
    final_optimization
}

# Main Execution & Exit script successfully
 sync && main