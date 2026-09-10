#define _GNU_SOURCE
#include <QString>
#include <QUrl>
#include <dlfcn.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

static void fdm_fix_log(const char *fmt, ...) {
    FILE *f = fopen("/tmp/fdm-portal-fix.log", "a");
    if (!f) return;
    va_list args;
    va_start(args, fmt);
    fprintf(f, "[%ld] ", (long)time(NULL));
    vfprintf(f, fmt, args);
    fprintf(f, "\n");
    va_end(args);
    fclose(f);
}

typedef void (*qurl_toLocalFile_fn)(void *ret, const void *self);
static qurl_toLocalFile_fn orig_qurl_toLocalFile = NULL;

extern "C" {

void _ZNK4QUrl11toLocalFileEv(void *ret, const void *self) {
    if (!orig_qurl_toLocalFile) {
        orig_qurl_toLocalFile = (qurl_toLocalFile_fn)dlsym(RTLD_NEXT, "_ZNK4QUrl11toLocalFileEv");
    }
    if (orig_qurl_toLocalFile) {
        orig_qurl_toLocalFile(ret, self);
    }

    void *caller = __builtin_return_address(0);
    Dl_info info;
    bool is_fdm = false;
    uintptr_t offset = 0;

    if (dladdr(caller, &info) && info.dli_fbase) {
        if (info.dli_fname && strstr(info.dli_fname, "fdm.bin")) {
            is_fdm = true;
            offset = (uintptr_t)caller - (uintptr_t)info.dli_fbase;
        }
    }

    if (!is_fdm) {
        return;
    }

    const char *home = getenv("HOME");
    if (!home) home = "/home/walid";

    char fdm_cache[1024];
    snprintf(fdm_cache, sizeof(fdm_cache), "%s/.cache/fdm_last_selected_folder", home);

    char last_used[1024];
    snprintf(last_used, sizeof(last_used), "%s/.cache/last_used_directory", home);

    struct stat st;
    time_t now = time(NULL);

    bool should_check = (offset == 0x1d2ea6);
    if (!should_check) {
        if (stat(fdm_cache, &st) == 0 && (now - st.st_mtime) <= 5) {
            should_check = true;
        }
    }

    if (!should_check) {
        return;
    }

    char chosen_folder[1024] = {0};
    bool found = false;

    // 1. Check fdm_last_selected_folder first (within 10s)
    if (stat(fdm_cache, &st) == 0 && (now - st.st_mtime) <= 10) {
        FILE *f = fopen(fdm_cache, "r");
        if (f) {
            if (fgets(chosen_folder, sizeof(chosen_folder), f)) {
                char *nl = strchr(chosen_folder, '\n'); if (nl) *nl = '\0';
                nl = strchr(chosen_folder, '\r'); if (nl) *nl = '\0';
                if (chosen_folder[0] == '/') found = true;
            }
            fclose(f);
        }
        unlink(fdm_cache); // consume so it's only used once
    }

    // 2. Fallback to last_used_directory if within 5s
    if (!found && stat(last_used, &st) == 0 && (now - st.st_mtime) <= 5) {
        FILE *f = fopen(last_used, "r");
        if (f) {
            if (fgets(chosen_folder, sizeof(chosen_folder), f)) {
                char *nl = strchr(chosen_folder, '\n'); if (nl) *nl = '\0';
                nl = strchr(chosen_folder, '\r'); if (nl) *nl = '\0';
                if (chosen_folder[0] == '/') found = true;
            }
            fclose(f);
        }
    }

    if (found && chosen_folder[0] == '/') {
        struct stat dir_st;
        if (stat(chosen_folder, &dir_st) == 0 && S_ISDIR(dir_st.st_mode)) {
            QString *qstr = reinterpret_cast<QString*>(ret);
            *qstr = QString::fromUtf8(chosen_folder);
            fdm_fix_log("Caller offset 0x%lx: successfully overrode path to '%s'", (unsigned long)offset, chosen_folder);
        }
    }
}

} // extern "C"
