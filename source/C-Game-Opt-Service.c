#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define GAME_FILE_PATH "/sdcard/kazu/system/etc/gamelist.txt"
#define FPS 60
#define MIUI "miui_version_check_command"

void send_notification() {
    system("cmd notification post -S bigtext -t 'Celestial-Game-Opt 🪽' 'tag' 'Status : Optimization Completed!' >/dev/null 2>&1");
}

void game_manager() {
    FILE *file = fopen(GAME_FILE_PATH, "r");
    if (!file) {
        printf("File GAME tidak ditemukan atau tidak ditentukan.\n");
        return;
    }

    char game[256];
    while (fgets(game, sizeof(game), file)) {
        game[strcspn(game, "\n")] = 0;  // Remove newline character
        if (strlen(game) > 0) {
            // Assuming we have a function to set game performance (which would need implementation)
            char command[512];
            snprintf(command, sizeof(command), "cmd game mode performance %s set --fps %d", game, FPS);
            system(command);
        }
    }

    fclose(file);
}

void miui_boost_feature() {
    // Checking MIUI property (in C, this would involve checking a system property)
    if (system(MIUI) == 0) { // Assumes MIUI returns 0 if present
        system("setprop debug.power.monitor_tools false");
        system("write system POWER_BALANCED_MODE_OPEN 0");
        system("write system POWER_PERFORMANCE_MODE_OPEN 1");
        system("write system POWER_SAVE_MODE_OPEN 0");
        system("write system power_mode middle");
        system("write system POWER_SAVE_PRE_HIDE_MODE performance");
        system("write system POWER_SAVE_PRE_SYNCHRONIZE_ENABLE 1");
    } else {
        printf("[WARN] ERRORS!\n");
    }
}

void final_optimization() {
    system("setprop debug.performance.tuning 1");
    system("setprop debug.sf.hw 1");
    system("setprop debug.egl.hw 1");
    system("write global activity_manager_constants \"power_check_max_cpu_1=0,power_check_max_cpu_2=0,power_check_max_cpu_3=0,power_check_max_cpu_4=0,power_check_max_cpu_5=0,power_check_max_cpu_6=0,power_check_max_cpu_7=0,power_check_max_cpu_8=0\"");
    system("cmd stats clear-puller-cache");
    system("cmd display ab-logging-disable");
    system("cmd display dwb-logging-disable");
    system("cmd display set-match-content-frame-rate-pref 2");
    system("logcat -c --wrap");
    system("simpleperf --log fatal --log-to-android-buffer 0");
    system("cmd activity clear-watch-heap -a");
    system("cmd looper_stats disable");
    system("am memory-factor set CRITICAL");
    system("cmd power set-adaptive-power-saver-enabled false");
    system("cmd power set-fixed-performance-mode-enabled true");
    system("cmd thermalservice override-status 0");
}

void main_execution() {
    game_manager();
    miui_boost_feature();
    final_optimization();
    send_notification();
}

int main() {
    main_execution();
    return 0;
}