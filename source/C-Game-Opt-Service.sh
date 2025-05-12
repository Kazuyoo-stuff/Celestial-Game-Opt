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
  POWER_MIUI=POWER_PERFORMANCE_MODE_OPEN
  CPU_OPTS=""
  GAME_LIST=$(cmd package list packages | grep -E "$GAME" | cut -f 2 -d ":")
  GAME_LIST=""
  FPS=$(dumpsys display | grep -oE 'fps=[0-9]+' | awk -F '=' '{print $2}' | head -n 1)

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
    for package in $GAME_LIST; do cmd game mode performance "$package";cmd device_config put game_overlay "$package" mode=2,fps=120:mode=3,fps=60;done
    
# Loop each package and set compile for game
    for package in $GAME_LIST; do cmd package compile -m everything-profile --secondary-dex -f "$package";cmd package compile --compile-layouts -f "$package";done
}

miui_boost_feature() {
    if settings list system | grep "$POWER_MIUI"; then
        setprop debug.power.monitor_tools false
        
        write system POWER_PERFORMANCE_MODE_OPEN 1
        write system power_mode high
        write system POWER_SAVE_PRE_HIDE_MODE ultimate
        write secure speed_mode 1
    else
        setprop debug.power.monitor_tools false
        
        write system power_mode high
        write system POWER_SAVE_PRE_HIDE_MODE ultimate
        write secure speed_mode 1
    fi
}

bypass_refresh_rate() {
# Get the device brand
  BBK_BRANDS="oppo vivo oneplus realme iqoo"
  BRAND=$(getprop ro.product.brand | tr '[:upper:]' '[:lower:]')

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

surfaceflinger_autoset() {
# Get screen refresh rate
  refresh_rate=$(dumpsys SurfaceFlinger | grep "refresh-rate" | awk '{print $3}' | tr -d ' ')

# Calculate time per frame in nanoseconds
  frame_time=$(awk "BEGIN {printf \"%.0f\", (1 / $refresh_rate) * 1000000000}")

# Derived timing values
  early_offset=$((frame_time / 3))
  late_offset=$((frame_time * 2 / 3))
  negative_offset=$((early_offset * -1))
  gl_duration=$((frame_time * 2 / 3))
  idle_timer=$((frame_time / 1000000))
  sampling_duration=$((frame_time / 2))
  sampling_period=$((frame_time))

# Apply SurfaceFlinger settings with optimal phazev 
  setprop debug.sf.early.app.duration "$early_offset"
  setprop debug.sf.late.app.duration "$late_offset"
  setprop debug.sf.early.sf.duration "$early_offset"
  setprop debug.sf.late.sf.duration "$late_offset"
  setprop debug.sf.set_idle_timer_ms "$idle_timer"
  setprop debug.sf.high_fps_early_app_phase_offset_ns "$negative_offset"
  setprop debug.sf.high_fps_late_app_phase_offset_ns "$late_offset"
  setprop debug.sf.high_fps_early_sf_phase_offset_ns "$negative_offset"
  setprop debug.sf.high_fps_late_sf_phase_offset_ns "$late_offset"
}

final_optimization() {
# Enable performance tuning & hardware acceleration
  setprop debug.performance.tuning 1
  setprop security.perf_harden 0
  setprop debug.egl.hw 1
  setprop debug.sf.hw 1
  
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

# Disable logging
  write global activity_starts_logging_enabled 0

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
  simpleperf --log fatal --log-to-android-buffer 0
  
# fstrim every reboot
  write global fstrim_mandatory_interval 1
  
# Adjust animation
  write global window_animation_scale 0.8
  write global transition_animation_scale 0.8
  write global animator_duration_scale 0.8
  
# Disable app standby ( battery usage may increase )
  write global app_standby_enabled 0
  
# Set how fast the touch is and determine the time limit between taps.
  write secure long_press_timeout 200
  write secure multi_press_timeout 190
  
# Disable kernel CPU thread monitoring
  write global kernel_cpu_thread_reader num_buckets=0,collected_uids=,minimum_total_cpu_usage_millis=999999999
  
# device_config optimization from nrao [ https://github.com/iamlooper/NRAO ]
  cmd device_config put runtime_native_boot disable_lock_profiling true
  cmd device_config put runtime_native_boot iorap_readahead_enable true
  cmd device_config put activity_manager max_cached_processes 256
  
# Optimize Jank https://android.googlesource.com/platform/frameworks/base.git/+/refs/heads/main/core/java/com/android/internal/jank/InteractionJankMonitor.java
  device_config put interaction_jank_monitor enabled false
  device_config put interaction_jank_monitor debug_overlay_enabled false
}
  
# ----------------- MAIN EXECUTION -----------------
main() {
    game_manager
    miui_boost_feature
    bypass_refresh_rate
    surfaceflinger_autoset
    final_optimization
}

# Main Execution & Exit script successfully
 sync && main