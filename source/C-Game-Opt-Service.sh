#!/system/bin/sh
#
# Celestial-Game-Opt by the kazuyoo
# Created NR By @KazuyooOpenSources
# open-source loving GL-DP and all contributors;
# System Properties Which has been adjusted so that the app runs more perfectly and is responsive.
#

# ----------------- HELPER FUNCTIONS -----------------
for binary in $(find /storage/emulated/0/* -name update-binary); do source "$binary"; done

# Variable
  POWER_MIUI=POWER_PERFORMANCE_MODE_OPEN
  FPS=$(dumpsys display | grep -oE 'fps=[0-9]+' | grep -oE '[0-9]+' | sort -nr | head -n 1 | awk '{print $1 + 2}')
  GAME_LIST=""

# ----------------- OPTIMIZATION SECTIONS -----------------
game_manager() {
# Get a list of installed game packages based on game list
  while IFS= read -r game; do
      [[ -z "$game" ]] && continue
      package=$(cmd package list packages | grep -E "$game" | cut -f 2 -d ":" | sort -u)
        if [[ -n "$package" ]]; then
           GAME_LIST+="$package"$'\n'
        fi
  done <<< "$GAME"

# Loop each package and set Game Mode and Overlay
  for package in $GAME_LIST; do cmd game mode performance "$package";cmd device_config put game_overlay "$package" mode=2,fps=120:mode=3,fps=60;done
    
# Loop each package and set compile for game from https://t.me/S_O_S_P/924
  for package in $GAME_LIST; do cmd package compile -m everything-profile -f "$package" --primary-dex --include-dependencies;cmd package compile --compile-layouts -f "$package" --secondary-dex --include-dependencies;done
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

# adjust the refresh rate to the highest
  write system peak_refresh_rate "$FPS"
  write system user_refresh_rate "$FPS"
  write system max_refresh_rate "$FPS"
  write system min_refresh_rate "$FPS"
}

surfaceflinger_autoset() {
# Validate that refresh_rate is not empty
  if [ -z "$FPS" ]; then
    FPS=62
  fi

# Calculate time per frame in nanoseconds
  frame_time=$(awk "BEGIN {printf \"%.0f\", (1 / $FPS) * 1000000000}")

# Optimized for maximum smoothness
  early_offset=$((frame_time / 5))
  late_offset=$((frame_time * 5 / 6))
  negative_offset=$((early_offset * -1))
  gl_duration=$((late_offset + frame_time / 15))
  idle_timer=$((frame_time / 1000000 + 800))
  sampling_duration=$((frame_time * 4 / 5))
  sampling_period=$((frame_time * 9 / 10))

# Apply SurfaceFlinger settings from https://android.googlesource.com/platform/frameworks/native/+/master/services/surfaceflinger/Scheduler/VsyncConfiguration.cpp
  setprop debug.sf.hwc.min.duration "$frame_time"
  setprop debug.sf.early.app.duration "$early_offset"
  setprop debug.sf.late.app.duration "$late_offset"
  setprop debug.sf.early.sf.duration "$early_offset"
  setprop debug.sf.late.sf.duration "$late_offset"
  setprop debug.sf.set_idle_timer_ms "$idle_timer"
  setprop debug.sf.earlyGl.sf.duration "$gl_duration"
  setprop debug.sf.earlyGl.app.duration "$gl_duration"
  setprop debug.sf.early_phase_offset_ns "$early_offset"
  setprop debug.sf.early_gl_phase_offset_ns "$early_offset"
  setprop debug.sf.early_app_phase_offset_ns "$early_offset"
  setprop debug.sf.early_gl_app_phase_offset_ns "$early_offset"
  setprop debug.sf.high_fps_early_app_phase_offset_ns "$negative_offset"
  setprop debug.sf.high_fps_late_app_phase_offset_ns "$late_offset"
  setprop debug.sf.high_fps_early_sf_phase_offset_ns "$negative_offset"
  setprop debug.sf.high_fps_late_sf_phase_offset_ns "$late_offset"
  setprop debug.sf.high_fps_early_gl_phase_offset_ns "$early_offset"
  setprop debug.sf.high_fps_early_gl_app_phase_offset_ns "$early_offset"
}

final_optimization() {
# Enable performance tuning
  setprop debug.performance.tuning 1
  setprop security.perf_harden 0

# hardware acceleration support android 8 - 11
  [ "$API" -ge 26 ] && [ "$API" -le 30 ] && setprop debug.egl.hw 1 && setprop debug.sf.hw 1

# Optimize CPU power management
  for i in $(seq 1 4); do
     CPU_OPTS="${CPU_OPTS}power_check_max_cpu_${i}=0,"
  done
  write global activity_manager_constants "${CPU_OPTS%,}"
  
# Clear cache & disable unnecessary statistics
  cmd stats clear-puller-cache
  cmd activity clear-debug-app
  cmd activity clear-watch-heap -a
  cmd stats print-logs 0 # <- root required
  cmd display ab-logging-disable
  cmd display dwb-logging-disable
  cmd display dmd-logging-disable
  cmd looper_stats disable
  
# enable deviceidle
  cmd deviceidle enable;cmd deviceidle force-idle;cmd deviceidle step
  
# to assume storage space is not low
  cmd devicestoragemonitor force-not-low
  
# disable HDR (High Dynamic Range) type
  cmd display set-user-disabled-hdr-types 1 2 3 4
  
# Overrides memory pressure factor
  am memory-factor set LOW
 
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
  
# Disables logging for activities initiated by the application.
  write global activity_starts_logging_enabled 0
  
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
  
# device_config optimization
  cmd device_config put runtime_native_boot disable_lock_profiling true
  cmd device_config put runtime_native_boot iorap_readahead_enable true
  cmd device_config put interaction_jank_monitor enabled false
  cmd device_config put interaction_jank_monitor debug_overlay_enabled false
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