#define _GNU_SOURCE
#include <gtk/gtk.h>
#include <dlfcn.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define CACHE_FILE_REL "/.cache/last_used_directory"

static void get_cache_file(char *buf, size_t size) {
    const char *home = getenv("HOME");
    if (!home) home = "/home/walid";
    snprintf(buf, size, "%s%s", home, CACHE_FILE_REL);
}

static void update_qt_project_conf(const char *path) {
    const char *home = getenv("HOME");
    if (!home || !path) return;
    char conf_path[1024];
    snprintf(conf_path, sizeof(conf_path), "%s/.config/QtProject.conf", home);

    FILE *f = fopen(conf_path, "r");
    if (!f) return;

    char temp_path[1024];
    snprintf(temp_path, sizeof(temp_path), "%s.tmp.%d", conf_path, (int)getpid());
    FILE *out = fopen(temp_path, "w");
    if (!out) {
        fclose(f);
        return;
    }

    char line[4096];
    int updated = 0;
    while (fgets(line, sizeof(line), f)) {
        if (strncmp(line, "lastVisited=", 12) == 0) {
            fprintf(out, "lastVisited=file://%s\n", path);
            updated = 1;
        } else {
            fputs(line, out);
        }
    }
    if (!updated) {
        fprintf(out, "lastVisited=file://%s\n", path);
    }
    fclose(f);
    fclose(out);
    rename(temp_path, conf_path);
}

static void save_last_dir(const char *dir) {
    if (!dir || dir[0] != '/') return;
    struct stat st;
    if (stat(dir, &st) != 0 || !S_ISDIR(st.st_mode)) return;

    char cache_path[1024];
    get_cache_file(cache_path, sizeof(cache_path));

    char temp_path[1024];
    snprintf(temp_path, sizeof(temp_path), "%s.tmp.%d", cache_path, (int)getpid());
    FILE *f = fopen(temp_path, "w");
    if (f) {
        fputs(dir, f);
        fclose(f);
        rename(temp_path, cache_path);
    }

    update_qt_project_conf(dir);
}

static char* load_last_dir(void) {
    char cache_path[1024];
    get_cache_file(cache_path, sizeof(cache_path));
    FILE *f = fopen(cache_path, "r");
    if (!f) return NULL;

    char buf[1024];
    if (!fgets(buf, sizeof(buf), f)) {
        fclose(f);
        return NULL;
    }
    fclose(f);

    char *nl = strchr(buf, '\n');
    if (nl) *nl = '\0';
    nl = strchr(buf, '\r');
    if (nl) *nl = '\0';

    if (buf[0] != '/') return NULL;
    struct stat st;
    if (stat(buf, &st) == 0 && S_ISDIR(st.st_mode)) {
        return strdup(buf);
    }
    return NULL;
}

static int is_default_generic_path(const char *path) {
    if (!path || path[0] == '\0') return 1;

    const char *home = getenv("HOME");
    if (!home) home = "/home/walid";

    // Is it home?
    if (strcmp(path, home) == 0) return 1;

    size_t homelen = strlen(home);
    if (strncmp(path, home, homelen) == 0 && (path[homelen] == '\0' || strcmp(path + homelen, "/") == 0)) {
        return 1;
    }

    // Default download directories that apps fall back to
    const char *defaults[] = {
        "/home/walid/Downloads",
        "/home/walid/Downloads/",
        "/home/walid/E/Downloads",
        "/home/walid/E/Downloads/",
        "/home/walid/Downloads/Telegram Desktop",
        "/home/walid/Downloads/Telegram Desktop/",
        "/home/walid/E/Downloads/Telegram Desktop",
        "/home/walid/E/Downloads/Telegram Desktop/",
        NULL
    };

    for (int i = 0; defaults[i]; ++i) {
        if (strcmp(path, defaults[i]) == 0) return 1;
    }

    // Check if it's inside Telegram cache
    if (strstr(path, "/.local/share/AyuGramDesktop") ||
        strstr(path, "/.local/share/TelegramDesktop")) {
        return 1;
    }

    return 0;
}

/* ── Location Entry Handlers (Thunar Style) ── */

static void on_location_entry_icon_press(GtkEntry *entry, GtkEntryIconPosition icon_pos, GdkEvent *event, gpointer user_data) {
    GtkFileChooser *chooser = GTK_FILE_CHOOSER(user_data);
    if (icon_pos == GTK_ENTRY_ICON_PRIMARY) {
        const char *home = getenv("HOME");
        if (home) {
            gtk_file_chooser_set_current_folder(chooser, home);
        }
    }
}

static void on_location_entry_activate(GtkEntry *entry, gpointer user_data) {
    GtkFileChooser *chooser = GTK_FILE_CHOOSER(user_data);
    const char *raw_path = gtk_entry_get_text(entry);
    if (!raw_path || raw_path[0] == '\0') return;

    char resolved[1024];
    if (raw_path[0] == '~') {
        const char *home = getenv("HOME");
        if (!home) home = "/home/walid";
        snprintf(resolved, sizeof(resolved), "%s%s", home, raw_path + 1);
    } else {
        snprintf(resolved, sizeof(resolved), "%s", raw_path);
    }

    size_t len = strlen(resolved);
    if (len > 1 && resolved[len - 1] == '/') {
        resolved[len - 1] = '\0';
    }

    if (g_file_test(resolved, G_FILE_TEST_IS_DIR)) {
        gtk_file_chooser_set_current_folder(chooser, resolved);
    }
}

static void on_current_folder_changed(GtkFileChooser *chooser, gpointer user_data) {
    GtkEntry *entry = GTK_ENTRY(user_data);
    char *folder = gtk_file_chooser_get_current_folder(chooser);
    if (folder) {
        gtk_entry_set_text(entry, folder);
        g_free(folder);
    }
}

static void attach_typable_location_bar(GtkWidget *widget, GtkFileChooser *chooser) {
    if (!widget) return;
    const char *name = gtk_widget_get_name(widget);
    if (name && strcmp(name, "pathbarbox") == 0) {
        if (g_object_get_data(G_OBJECT(widget), "typable_bar_installed")) {
            return;
        }
        g_object_set_data(G_OBJECT(widget), "typable_bar_installed", GINT_TO_POINTER(1));

        // Hide existing breadcrumb bar
        GList *children = gtk_container_get_children(GTK_CONTAINER(widget));
        for (GList *l = children; l != NULL; l = l->next) {
            gtk_widget_hide(GTK_WIDGET(l->data));
        }
        g_list_free(children);

        // Create Thunar-style location entry
        GtkWidget *entry = gtk_entry_new();
        gtk_entry_set_icon_from_icon_name(GTK_ENTRY(entry), GTK_ENTRY_ICON_PRIMARY, "go-home-symbolic");
        gtk_entry_set_icon_activatable(GTK_ENTRY(entry), GTK_ENTRY_ICON_PRIMARY, TRUE);
        gtk_entry_set_icon_tooltip_text(GTK_ENTRY(entry), GTK_ENTRY_ICON_PRIMARY, "Home");

        gtk_widget_set_hexpand(entry, TRUE);
        gtk_widget_set_margin_start(entry, 4);
        gtk_widget_set_margin_end(entry, 4);
        gtk_widget_set_margin_top(entry, 2);
        gtk_widget_set_margin_bottom(entry, 2);

        char *curr = gtk_file_chooser_get_current_folder(chooser);
        if (curr) {
            gtk_entry_set_text(GTK_ENTRY(entry), curr);
            g_free(curr);
        }

        g_signal_connect(entry, "activate", G_CALLBACK(on_location_entry_activate), chooser);
        g_signal_connect(entry, "icon-press", G_CALLBACK(on_location_entry_icon_press), chooser);
        g_signal_connect(chooser, "current-folder-changed", G_CALLBACK(on_current_folder_changed), entry);

        gtk_box_pack_start(GTK_BOX(widget), entry, TRUE, TRUE, 0);
        gtk_widget_show(entry);
        return;
    }

    if (GTK_IS_CONTAINER(widget)) {
        GList *children = gtk_container_get_children(GTK_CONTAINER(widget));
        for (GList *l = children; l != NULL; l = l->next) {
            attach_typable_location_bar(GTK_WIDGET(l->data), chooser);
        }
        g_list_free(children);
    }
}

// Function pointer typedefs
typedef gboolean (*orig_set_current_folder_fn)(GtkFileChooser *, const gchar *);
typedef GSList* (*orig_get_uris_fn)(GtkFileChooser *);
typedef gchar* (*orig_get_filename_fn)(GtkFileChooser *);
typedef GSList* (*orig_get_filenames_fn)(GtkFileChooser *);
typedef void (*orig_widget_show_fn)(GtkWidget *);

static orig_set_current_folder_fn orig_set_current_folder = NULL;
static orig_get_uris_fn orig_get_uris = NULL;
static orig_get_filename_fn orig_get_filename = NULL;
static orig_get_filenames_fn orig_get_filenames = NULL;
static orig_widget_show_fn orig_widget_show = NULL;

__attribute__((constructor))
static void init(void) {
    orig_set_current_folder = (orig_set_current_folder_fn)dlsym(RTLD_NEXT, "gtk_file_chooser_set_current_folder");
    orig_get_uris = (orig_get_uris_fn)dlsym(RTLD_NEXT, "gtk_file_chooser_get_uris");
    orig_get_filename = (orig_get_filename_fn)dlsym(RTLD_NEXT, "gtk_file_chooser_get_filename");
    orig_get_filenames = (orig_get_filenames_fn)dlsym(RTLD_NEXT, "gtk_file_chooser_get_filenames");
    orig_widget_show = (orig_widget_show_fn)dlsym(RTLD_NEXT, "gtk_widget_show");
}

gboolean gtk_file_chooser_set_current_folder(GtkFileChooser *chooser, const gchar *filename) {
    if (!orig_set_current_folder) {
        orig_set_current_folder = (orig_set_current_folder_fn)dlsym(RTLD_NEXT, "gtk_file_chooser_set_current_folder");
    }

    const char *target = filename;
    char *last = NULL;

    if (is_default_generic_path(filename)) {
        last = load_last_dir();
        if (last) {
            target = last;
        }
    }

    gboolean res = orig_set_current_folder ? orig_set_current_folder(chooser, target) : FALSE;
    if (last) free(last);
    return res;
}

void gtk_widget_show(GtkWidget *widget) {
    if (!orig_widget_show) {
        orig_widget_show = (orig_widget_show_fn)dlsym(RTLD_NEXT, "gtk_widget_show");
    }

    if (GTK_IS_FILE_CHOOSER(widget)) {
        GtkFileChooser *chooser = GTK_FILE_CHOOSER(widget);
        gchar *current = gtk_file_chooser_get_current_folder(chooser);
        if (is_default_generic_path(current)) {
            char *last = load_last_dir();
            if (last) {
                if (orig_set_current_folder) {
                    orig_set_current_folder(chooser, last);
                }
                free(last);
            }
        }
        if (current) g_free(current);

        attach_typable_location_bar(widget, chooser);
    }

    if (orig_widget_show) {
        orig_widget_show(widget);
    }
}

GSList* gtk_file_chooser_get_uris(GtkFileChooser *chooser) {
    if (!orig_get_uris) {
        orig_get_uris = (orig_get_uris_fn)dlsym(RTLD_NEXT, "gtk_file_chooser_get_uris");
    }

    GSList *uris = orig_get_uris ? orig_get_uris(chooser) : NULL;
    if (uris && uris->data) {
        char *uri = (char *)uris->data;
        char *filename = g_filename_from_uri(uri, NULL, NULL);
        if (filename) {
            char *dirname = g_path_get_dirname(filename);
            if (dirname) {
                save_last_dir(dirname);
                g_free(dirname);
            }
            g_free(filename);
        }
    }
    return uris;
}

gchar* gtk_file_chooser_get_filename(GtkFileChooser *chooser) {
    if (!orig_get_filename) {
        orig_get_filename = (orig_get_filename_fn)dlsym(RTLD_NEXT, "gtk_file_chooser_get_filename");
    }

    gchar *filename = orig_get_filename ? orig_get_filename(chooser) : NULL;
    if (filename) {
        char *dirname = g_path_get_dirname(filename);
        if (dirname) {
            save_last_dir(dirname);
            g_free(dirname);
        }
    }
    return filename;
}

GSList* gtk_file_chooser_get_filenames(GtkFileChooser *chooser) {
    if (!orig_get_filenames) {
        orig_get_filenames = (orig_get_filenames_fn)dlsym(RTLD_NEXT, "gtk_file_chooser_get_filenames");
    }

    GSList *filenames = orig_get_filenames ? orig_get_filenames(chooser) : NULL;
    if (filenames && filenames->data) {
        char *filename = (char *)filenames->data;
        char *dirname = g_path_get_dirname(filename);
        if (dirname) {
            save_last_dir(dirname);
            g_free(dirname);
        }
    }
    return filenames;
}
