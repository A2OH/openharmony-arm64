#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <string.h>

int main(int argc, char **argv) {
    /* Mount essential filesystems */
    mount("proc", "/proc", "proc", 0, NULL);
    mount("sysfs", "/sys", "sysfs", 0, NULL);
    mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
    mount("tmpfs", "/tmp", "tmpfs", 0, NULL);

    printf("\n");
    printf("============================================\n");
    printf("  OpenHarmony ARM64 QEMU - Minimal Init\n");
    printf("  Westlake / A2OH Project\n");
    printf("============================================\n");
    printf("\n");

    /* Print system info */
    printf("[init] PID 1 running on aarch64\n");
    FILE *cpuinfo = fopen("/proc/cpuinfo", "r");
    if (cpuinfo) {
        char line[256];
        while (fgets(line, sizeof(line), cpuinfo)) {
            if (strncmp(line, "processor", 9) == 0 ||
                strncmp(line, "CPU", 3) == 0 ||
                strncmp(line, "Features", 8) == 0 ||
                strncmp(line, "BogoMIPS", 8) == 0) {
                printf("[cpuinfo] %s", line);
            }
        }
        fclose(cpuinfo);
    }

    FILE *meminfo = fopen("/proc/meminfo", "r");
    if (meminfo) {
        char line[256];
        int count = 0;
        while (fgets(line, sizeof(line), meminfo) && count < 3) {
            printf("[meminfo] %s", line);
            count++;
        }
        fclose(meminfo);
    }

    printf("\n[init] System ready.\n");
    printf("[init] To deploy ART/Dalvik, use: scripts/deploy_art.sh\n");
    printf("\n");

    /* If /art/dalvikvm exists, run it */
    if (access("/art/dalvikvm", X_OK) == 0) {
        printf("[init] Found /art/dalvikvm, launching...\n");
        pid_t pid = fork();
        if (pid == 0) {
            setenv("ANDROID_DATA", "/tmp/android-data", 1);
            setenv("ANDROID_ROOT", "/art", 1);
            mkdir("/tmp/android-data", 0755);
            mkdir("/tmp/android-data/dalvik-cache", 0755);
            /* A15 ART imageless mode (no boot image) */
            mkdir("/tmp/android-data/dalvik-cache/arm64", 0755);
            char *args[] = {
                "/art/dalvikvm",
                "-Xbootclasspath:/art/core-oj.jar:/art/core-libart.jar:/art/core-icu4j.jar",
                "-Xverify:none",
                "-Xusejit:false",
                "-classpath", "/art/test.dex",
                "FibOnly",
                NULL
            };
            execv("/art/dalvikvm", args);
            printf("[init] execv failed\n");
            _exit(1);
        } else if (pid > 0) {
            int status;
            waitpid(pid, &status, 0);
            printf("[init] dalvikvm exited with status %d\n", WEXITSTATUS(status));
        }
    }

    /* Drop to a shell if /bin/sh exists */
    if (access("/bin/sh", X_OK) == 0) {
        printf("[init] Starting shell...\n");
        execl("/bin/sh", "sh", NULL);
    }

    /* Otherwise just idle */
    printf("[init] No shell available, halting.\n");
    printf("[init] SUCCESS: ARM64 QEMU boot verified!\n");
    while (1) { sleep(999999); }
    return 0;
}
