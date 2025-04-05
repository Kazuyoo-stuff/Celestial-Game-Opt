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
  POWER_MIUI=$(settings get system POWER_PERFORMANCE_MODE_OPEN)
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
    for package in $GAME_LIST; do
        if cmd game mode performance "$package" set --fps "$FPS"; then
            if cmd device_config put game_overlay "$package" mode=2,fps=120:mode=3,fps=60; then
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
    if [[ "$POWER_MIUI" == "1" ]]; then
        setprop debug.power.monitor_tools false
        
        write system POWER_PERFORMANCE_MODE_OPEN 1
        write system POWER_SAVE_MODE_OPEN 0
        write system power_mode high
        write system POWER_SAVE_PRE_HIDE_MODE ultimate
        write system POWER_SAVE_PRE_SYNCHRONIZE_ENABLE 0
        write system speed_mode 1
    else
        write system POWER_SAVE_MODE_OPEN 0
        write system power_mode high
        write system POWER_SAVE_PRE_HIDE_MODE ultimate
        write system POWER_SAVE_PRE_SYNCHRONIZE_ENABLE 0
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

# Calculate various offsets based on frame_time
phazev1=$((frame_time / 8))
phazev2=$((frame_time / 5))
phazev3=$((frame_time / 3))
phazev4=$((frame_time / 2))
phazev5=$((frame_time * 2 / 3))
phazev6=$((frame_time))
phazev7=$((frame_time * 5 / 4))

# Apply SurfaceFlinger settings with optimal phazev 
setprop debug.sf.earlyGl.app.duration "$phazev5"
setprop debug.sf.earlyGl.sf.duration "$phazev5"
setprop debug.sf.hwc.min.duration "$phazev5"
setprop debug.sf.early.app.duration "$phazev5"
setprop debug.sf.late.app.duration "$phazev6"
setprop debug.sf.early.sf.duration "$phazev5"
setprop debug.sf.late.sf.duration "$phazev6"

setprop debug.sf.set_idle_timer_ms "$phazev4"
setprop debug.sf.layer_caching_active_layer_timeout_ms "$phazev3"

setprop debug.sf.high_fps_early_app_phase_offset_ns "-$phazev3"
setprop debug.sf.high_fps_late_app_phase_offset_ns "$phazev2"
setprop debug.sf.high_fps_early_sf_phase_offset_ns "-$phazev3"
setprop debug.sf.high_fps_late_sf_phase_offset_ns "$phazev2"
setprop debug.sf.high_fps_early_gl_app_phase_offset_ns "$phazev1"
setprop debug.sf.high_fps_early_gl_phase_offset_ns "$phazev2"
setprop debug.sf.high_fps_early_phase_offset_ns "$phazev2"
setprop debug.sf.high_fps_late_app_phase_offset_ns "$phazev6"
setprop debug.sf.high_fps_late_sf_phase_offset_ns "$phazev6"

setprop debug.sf.vsync_phase_offset_ns "-$phazev2"
setprop debug.sf.vsync_event_phase_offset_ns "-$phazev2"

setprop debug.sf.region_sampling_duration_ns "$phazev4"
setprop debug.sf.cached_set_render_duration_ns "$phazev4"

setprop debug.sf.early_app_phase_offset_ns "$phazev2"
setprop debug.sf.early_gl_app_phase_offset_ns "$phazev2"

setprop debug.sf.early_gl_phase_offset_ns "$phazev4"
setprop debug.sf.early_phase_offset_ns "$phazev4"

setprop debug.sf.region_sampling_timer_timeout_ns "$phazev7"

setprop debug.sf.region_sampling_period_ns "$phazev6"
setprop debug.sf.phase_offset_threshold_for_next_vsync_ns "$phazev6"
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
  
# fstrim every reboot
  write global fstrim_mandatory_interval 1
  
# Adjust animation
  write global window_animation_scale 0.8
  write global transition_animation_scale 0.8
  write global animator_duration_scale 0.8
  
# Disable app standby ( battery usage may increase )
  write global app_standby_enabled 0
  
# device_config optimization from nrao [ https://github.com/iamlooper/NRAO ]
  cmd device_config put runtime_native_boot disable_lock_profiling true
  cmd device_config put runtime_native_boot iorap_readahead_enable true
  cmd device_config put activity_manager max_phantom_processes 2147483647
  cmd device_config put activity_manager max_cached_processes 256
  cmd device_config put activity_manager max_empty_time_millis 43200000
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