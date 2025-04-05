#!/system/bin/sh
# stops execution if the user running it is not UID 2000.
[ "$(id -u)" -ne 2000 ] && echo "[WARN] No shell permissions." && exit 1

# Load dependencies
source /storage/emulated/0/Kazu/META-INF/com/google/android/update-binary &>/dev/null || { echo "[ ! ] Error: Unable to load update-binary script."; exit 1; }

# Set logcat buffer size
LOGCAT_BUFFER=$(getprop dalvik.vm.heapgrowthlimit)
if [ -n "$LOGCAT_BUFFER" ]; then
    logcat -G "$LOGCAT_BUFFER"
else
    logcat -G 256K
fi

# Definition of variables
PROPFILE=true
POSTFSDATA=true
LATESTARTSERVICE=true
NAME="Celestial-Game-Opt | Kzyo"
VERSION="1.4"
DATE="Wed 8 Jan 2025"

# Function to print with a clearer format
print_line() {
    ui_print "***************************************"
}

ui_print ""
ui_print "░█▀▀█ ── ░█▀▀█ ─█▀▀█ ░█▀▄▀█ ░█▀▀▀ ── ░█▀▀▀█ ░█▀▀█ ▀▀█▀▀ 
░█─── ▀▀ ░█─▄▄ ░█▄▄█ ░█░█░█ ░█▀▀▀ ▀▀ ░█──░█ ░█▄▄█ ─░█── 
░█▄▄█ ── ░█▄▄█ ░█─░█ ░█──░█ ░█▄▄▄ ── ░█▄▄▄█ ░█─── ─░█──"
ui_print ""
sleep 0.5
ui_print " Tweaks & improvements for better gaming performance."
ui_print ""
print_line
ui_print "- Name            : ${NAME}"
sleep 0.2
ui_print "- Version         : ${VERSION}"
sleep 0.2
ui_print "- Android Version : ${ANDROIDVERSION:-Unknown}"
sleep 0.2
ui_print "- Build Date      : ${DATE}"
print_line
sleep 0.2
ui_print "- Devices         : ${DEVICES:-Unknown}"
sleep 0.2
ui_print "- Manufacturer    : ${MANUFACTURER:-Unknown}"
print_line
ui_print "- Trimming up Partitions"
execute_task "trim_partition"
ui_print "- Deleting Trash and Logs"
execute_task "delete_trash_logs"
ui_print "- Adjustments Advanced settings"
execute_task "install_tweak"
ui_print "- Done"
ui_print ""

# closing or peak completion of the flash module
wait && logcat -c && send_notification
