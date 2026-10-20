#include <QString>
#include <dlfcn.h>
#include <limits.h>
#include <new>
#include <stdint.h>
#include <sys/stat.h>
#include <unistd.h>
#include <time.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

typedef void (*qurl_toLocalFile_fn)(void *ret, const void *self);

static qurl_toLocalFile_fn original_qurl_to_local_file() {
    // Function-local static initialization is thread-safe in C++11 and later.
    static const auto function = reinterpret_cast<qurl_toLocalFile_fn>(
        dlsym(RTLD_NEXT, "_ZNK4QUrl11toLocalFileEv"));
    return function;
}

extern "C" {

void qurl_to_local_file_interpose(void *ret, const void *self)
    __asm__("_ZNK4QUrl11toLocalFileEv");

void qurl_to_local_file_interpose(void *ret, const void *self) {
    const qurl_toLocalFile_fn original = original_qurl_to_local_file();
    if (!original) {
        new (ret) QString();
        return;
    }
    original(ret, self);

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
    if (!home || home[0] != '/') return;

    const char *cache_home = getenv("XDG_CACHE_HOME");
    char cache_dir[PATH_MAX];
    if (cache_home && cache_home[0] == '/') {
        if (snprintf(cache_dir, sizeof(cache_dir), "%s", cache_home) >= (int)sizeof(cache_dir)) return;
    } else {
        if (snprintf(cache_dir, sizeof(cache_dir), "%s/.cache", home) >= (int)sizeof(cache_dir)) return;
    }

    char fdm_cache[PATH_MAX];
    const int fdm_cache_len = snprintf(
        fdm_cache, sizeof(fdm_cache), "%s/fdm_last_selected_folder", cache_dir);
    if (fdm_cache_len < 0 || (size_t)fdm_cache_len >= sizeof(fdm_cache)) return;

    char last_used[PATH_MAX];
    const int last_used_len = snprintf(
        last_used, sizeof(last_used), "%s/last_used_directory", cache_dir);
    if (last_used_len < 0 || (size_t)last_used_len >= sizeof(last_used)) return;

    struct stat st;
    time_t now = time(NULL);
    if (now == (time_t)-1) return;

    bool should_check = (offset == 0x1d2ea6);
    if (!should_check) {
        if (stat(fdm_cache, &st) == 0) {
            const double diff = difftime(now, st.st_mtime);
            if (diff >= -2.0 && diff <= 5.0) {
                should_check = true;
            }
        } else if (stat(last_used, &st) == 0) {
            const double diff = difftime(now, st.st_mtime);
            if (diff >= -2.0 && diff <= 5.0) {
                should_check = true;
            }
        }
    }

    if (!should_check) {
        return;
    }

    char chosen_folder[PATH_MAX] = {0};
    bool found = false;

    // 1. Check fdm_last_selected_folder first (within 10s)
    if (stat(fdm_cache, &st) == 0) {
        const double diff = difftime(now, st.st_mtime);
        if (diff >= -2.0 && diff <= 10.0) {
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
    }

    // 2. Fallback to last_used_directory if within 5s
    if (!found && stat(last_used, &st) == 0) {
        const double diff = difftime(now, st.st_mtime);
        if (diff >= -2.0 && diff <= 5.0) {
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
    }

    if (found && chosen_folder[0] == '/') {
        size_t flen = strlen(chosen_folder);
        while (flen > 1 && chosen_folder[flen - 1] == '/') {
            chosen_folder[--flen] = '\0';
        }
        struct stat dir_st;
        if (stat(chosen_folder, &dir_st) == 0 && S_ISDIR(dir_st.st_mode)) {
            auto *qstr = reinterpret_cast<QString*>(ret);
            *qstr = QString::fromUtf8(chosen_folder);
        }
    }
}

} // extern "C"
