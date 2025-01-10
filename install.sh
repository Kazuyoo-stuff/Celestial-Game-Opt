#!/system/bin/sh
# Load dependencies
source /storage/emulated/0/Kazu/META-INF/com/google/android/update-binary &>/dev/null || { echo "[ ! ] Error: Unable to load update-binary script."; exit 1; }

# array / variabel
NAME="Celestial-Game-Opt | Kzyo"
VERSION="1.0"
DATE="Wed 8 Jan 2025"

sleep 0.2
ui_print ""
ui_print "░█▀▀█ ── ░█▀▀█ ─█▀▀█ ░█▀▄▀█ ░█▀▀▀ ── ░█▀▀▀█ ░█▀▀█ ▀▀█▀▀ 
░█─── ▀▀ ░█─▄▄ ░█▄▄█ ░█░█░█ ░█▀▀▀ ▀▀ ░█──░█ ░█▄▄█ ─░█── 
░█▄▄█ ── ░█▄▄█ ░█─░█ ░█──░█ ░█▄▄▄ ── ░█▄▄▄█ ░█─── ─░█──"
ui_print ""
sleep 0.5
ui_print " tweaks & improvements to the Game."
ui_print ""
sleep 0.2
ui_print "***************************************"
ui_print "- Name            : ${NAME}"
sleep 0.2
ui_print "- Version         : ${VERSION}"
sleep 0.2
ui_print "- Android Version : ${ANDROIDVERSION}"
sleep 0.2
ui_print "- Build Date      : ${DATE}"
sleep 0.2
ui_print "***************************************"
ui_print "- Devices         : ${DEVICES}"
sleep 0.2
ui_print "- Manufacturer    : ${MANUFACTURER}"
ui_print "***************************************"
sleep 0.2
ui_print "- Trimming up Partitions"
trim_partition &>/dev/null
ui_print "- Delete trash and logs"
delete_trash_logs &>/dev/null
ui_print "- Final Installation Tweaks"
install_script &>/dev/null
sleep 0.5
ui_print "- Done"
ui_print ""