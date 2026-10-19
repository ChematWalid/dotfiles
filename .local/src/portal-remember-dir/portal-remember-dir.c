#include <gtk/gtk.h>
#include <glib/gstdio.h>
#include <dlfcn.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

static char *last_saved_directory = NULL;

static gboolean ensure_parent_directory(const char *file_path, const char *label) {
    char *directory = g_path_get_dirname(file_path);
    gboolean ok = g_mkdir_with_parents(directory, 0700) == 0;
    if (!ok) {
        g_warning("Could not create the %s directory", label);
    }
    g_free(directory);
    return ok;
}

static void update_qt_project_conf(const char *path) {
    const char *home = g_get_home_dir();
    if (!path) return;
    char *conf_path = g_build_filename(home, ".config", "QtProject.conf", NULL);
    char *contents = NULL;
    GError *read_error = NULL;
    if (!g_file_get_contents(conf_path, &contents, NULL, &read_error)) {
        if (!g_error_matches(read_error, G_FILE_ERROR, G_FILE_ERROR_NOENT)) {
            g_warning("Could not read the Qt file chooser location preference: %s",
                      read_error->message);
        }
        g_clear_error(&read_error);
        g_free(conf_path);
        return;
    }

    char *uri = g_filename_to_uri(path, NULL, NULL);
    if (!uri) {
        g_free(contents);
        g_free(conf_path);
        return;
    }

    char **lines = g_strsplit(contents, "\n", -1);
    GString *updated = g_string_new(NULL);
    gboolean found = FALSE;
    for (size_t i = 0; lines[i] != NULL; ++i) {
        if (g_str_has_prefix(lines[i], "lastVisited=")) {
            g_string_append_printf(updated, "lastVisited=%s", uri);
            found = TRUE;
        } else {
            g_string_append(updated, lines[i]);
        }
        if (lines[i + 1] != NULL) g_string_append_c(updated, '\n');
    }
    if (!found) g_string_append_printf(updated, "\nlastVisited=%s\n", uri);
    GError *error = NULL;
    if (!g_file_set_contents(conf_path, updated->str, -1, &error)) {
        g_warning("Could not update the GTK file chooser location preference: %s",
                  error->message);
        g_error_free(error);
    }
    g_string_free(updated, TRUE);
    g_strfreev(lines);
    g_free(uri);
    g_free(contents);
    g_free(conf_path);
}

static void save_last_dir(const char *dir) {
    if (!dir || dir[0] != '/') return;
    if (g_strcmp0(last_saved_directory, dir) == 0) return;

    struct stat st;
    if (stat(dir, &st) != 0 || !S_ISDIR(st.st_mode)) return;

    const char *home = g_get_home_dir();
    char *cache_path = g_build_filename(g_get_user_cache_dir(), "last_used_directory", NULL);
    char *fdm_cache = g_build_filename(home, ".cache", "fdm_last_selected_folder", NULL);
    GError *error = NULL;
    if (ensure_parent_directory(cache_path, "remembered-directory cache")) {
        if (!g_file_set_contents(cache_path, dir, -1, &error)) {
            g_warning("Could not save the remembered-directory cache: %s", error->message);
            g_clear_error(&error);
        } else if (g_chmod(cache_path, 0600) != 0) {
            g_warning("Could not restrict permissions on the remembered-directory cache");
        }
    }

    if (ensure_parent_directory(fdm_cache, "download-manager directory cache")) {
        if (!g_file_set_contents(fdm_cache, dir, -1, &error)) {
            g_warning("Could not save the download-manager directory cache: %s", error->message);
            g_clear_error(&error);
        } else if (g_chmod(fdm_cache, 0600) != 0) {
            g_warning("Could not restrict permissions on the download-manager directory cache");
        }
    }
    g_free(cache_path);
    g_free(fdm_cache);

    update_qt_project_conf(dir);

    g_free(last_saved_directory);
    last_saved_directory = g_strdup(dir);
}

static char* load_last_dir(void) {
    char *cache_path = g_build_filename(g_get_user_cache_dir(), "last_used_directory", NULL);
    char *path = NULL;
    gboolean loaded = g_file_get_contents(cache_path, &path, NULL, NULL);
    g_free(cache_path);
    if (!loaded) return NULL;

    gsize path_len = strlen(path);
    while (path_len > 0 && (path[path_len - 1] == '\n' || path[path_len - 1] == '\r')) {
        path[--path_len] = '\0';
    }
    if (path[0] != '/') {
        g_free(path);
        return NULL;
    }
    struct stat st;
    if (stat(path, &st) == 0 && S_ISDIR(st.st_mode)) {
        return path;
    }
    g_free(path);
    return NULL;
}

static int is_default_generic_path(const char *path) {
    if (!path || path[0] == '\0') return 1;

    const char *home = g_get_home_dir();

    // Is it home?
    if (strcmp(path, home) == 0) return 1;

    size_t homelen = strlen(home);
    if (strncmp(path, home, homelen) == 0 && (path[homelen] == '\0' || strcmp(path + homelen, "/") == 0)) {
        return 1;
    }

    // Default download directories that apps fall back to
    const char *defaults[] = {
        "Downloads",
        "Downloads/Telegram Desktop",
        ".local/share/AyuGramDesktop",
        ".local/share/TelegramDesktop",
        NULL
    };

    for (int i = 0; defaults[i]; ++i) {
        char *default_path = g_build_filename(home, defaults[i], NULL);
        gboolean matches = strcmp(path, default_path) == 0;
        g_free(default_path);
        if (matches) return 1;
    }

    // Check if it's inside Telegram cache
    return 0;
}

/* ── Location Entry Handlers (Thunar Style) ── */

static void on_location_entry_icon_press(GtkEntry *entry, GtkEntryIconPosition icon_pos, GdkEvent *event, gpointer user_data) {
    (void)entry;
    (void)event;
    GtkFileChooser *chooser = GTK_FILE_CHOOSER(user_data);
    if (icon_pos == GTK_ENTRY_ICON_PRIMARY) {
        const char *home = g_get_home_dir();
        if (home) {
            gtk_file_chooser_set_current_folder(chooser, home);
        }
    }
}

static void on_location_entry_activate(GtkEntry *entry, gpointer user_data) {
    GtkFileChooser *chooser = GTK_FILE_CHOOSER(user_data);
    const char *raw_path = gtk_entry_get_text(entry);
    if (!raw_path || raw_path[0] == '\0') return;

    char *resolved;
    if (raw_path[0] == '~') {
        const char *home = g_get_home_dir();
        if (raw_path[1] == '/' || raw_path[1] == '\0') {
            resolved = g_strdup_printf("%s%s", home, raw_path + 1);
        } else {
            resolved = g_strdup(raw_path);
        }
    } else {
        resolved = g_strdup(raw_path);
    }

    size_t len = strlen(resolved);
    if (len > 1 && resolved[len - 1] == '/') {
        resolved[len - 1] = '\0';
    }

    if (g_file_test(resolved, G_FILE_TEST_IS_DIR)) {
        gtk_file_chooser_set_current_folder(chooser, resolved);
    }
    g_free(resolved);
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

        // Keep GTK's breadcrumb controls and place the editable path beside them.
        GtkWidget *entry = gtk_entry_new();
        gtk_entry_set_icon_from_icon_name(GTK_ENTRY(entry), GTK_ENTRY_ICON_PRIMARY, "go-home-symbolic");
        gtk_entry_set_icon_activatable(GTK_ENTRY(entry), GTK_ENTRY_ICON_PRIMARY, TRUE);
        gtk_entry_set_icon_tooltip_text(GTK_ENTRY(entry), GTK_ENTRY_ICON_PRIMARY, "Home");
        gtk_entry_set_placeholder_text(GTK_ENTRY(entry), "Type a folder path and press Enter");

        gtk_widget_set_hexpand(entry, TRUE);
        gtk_widget_set_size_request(entry, 240, -1);
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

        gtk_box_pack_start(GTK_BOX(widget), entry, TRUE, TRUE, 4);
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

#define RESOLVE_NEXT(target, symbol_name)                 \
    do {                                                  \
        void *symbol = dlsym(RTLD_NEXT, (symbol_name));   \
        memcpy(&(target), &symbol, sizeof(target));       \
    } while (0)

__attribute__((constructor))
static void init(void) {
    RESOLVE_NEXT(orig_set_current_folder, "gtk_file_chooser_set_current_folder");
    RESOLVE_NEXT(orig_get_uris, "gtk_file_chooser_get_uris");
    RESOLVE_NEXT(orig_get_filename, "gtk_file_chooser_get_filename");
    RESOLVE_NEXT(orig_get_filenames, "gtk_file_chooser_get_filenames");
    RESOLVE_NEXT(orig_widget_show, "gtk_widget_show");
}

gboolean gtk_file_chooser_set_current_folder(GtkFileChooser *chooser, const gchar *filename) {
    if (!orig_set_current_folder) {
        RESOLVE_NEXT(orig_set_current_folder, "gtk_file_chooser_set_current_folder");
    }

    gpointer initialized = g_object_get_data(G_OBJECT(chooser), "remember_dir_initialized");
    gboolean is_visible = GTK_IS_WIDGET(chooser) && (gtk_widget_get_mapped(GTK_WIDGET(chooser)) || gtk_widget_get_realized(GTK_WIDGET(chooser)));

    const char *target = filename;
    char *last = NULL;

    if (!initialized && !is_visible && is_default_generic_path(filename)) {
        last = load_last_dir();
        if (last) {
            target = last;
        }
        g_object_set_data(G_OBJECT(chooser), "remember_dir_initialized", GINT_TO_POINTER(1));
    }

    gboolean res = orig_set_current_folder ? orig_set_current_folder(chooser, target) : FALSE;
    if (last) g_free(last);
    return res;
}

void gtk_widget_show(GtkWidget *widget) {
    if (!orig_widget_show) {
        RESOLVE_NEXT(orig_widget_show, "gtk_widget_show");
    }

    if (GTK_IS_FILE_CHOOSER(widget)) {
        GtkFileChooser *chooser = GTK_FILE_CHOOSER(widget);
        gpointer initialized = g_object_get_data(G_OBJECT(chooser), "remember_dir_initialized");
        if (!initialized) {
            gchar *current = gtk_file_chooser_get_current_folder(chooser);
            if (is_default_generic_path(current)) {
                char *last = load_last_dir();
                if (last) {
                    if (orig_set_current_folder) {
                        orig_set_current_folder(chooser, last);
                    }
                    g_free(last);
                }
            }
            if (current) g_free(current);
            g_object_set_data(G_OBJECT(chooser), "remember_dir_initialized", GINT_TO_POINTER(1));
        }

        attach_typable_location_bar(widget, chooser);
    }

    if (orig_widget_show) {
        orig_widget_show(widget);
    }
}

GSList* gtk_file_chooser_get_uris(GtkFileChooser *chooser) {
    if (!orig_get_uris) {
        RESOLVE_NEXT(orig_get_uris, "gtk_file_chooser_get_uris");
    }

    GSList *uris = orig_get_uris ? orig_get_uris(chooser) : NULL;
    if (uris && uris->data) {
        char *uri = (char *)uris->data;
        char *filename = g_filename_from_uri(uri, NULL, NULL);
        if (filename) {
            if (g_file_test(filename, G_FILE_TEST_IS_DIR)) {
                save_last_dir(filename);
            } else {
                char *dirname = g_path_get_dirname(filename);
                if (dirname) {
                    save_last_dir(dirname);
                    g_free(dirname);
                }
            }
            g_free(filename);
        }
    }
    return uris;
}

gchar* gtk_file_chooser_get_filename(GtkFileChooser *chooser) {
    if (!orig_get_filename) {
        RESOLVE_NEXT(orig_get_filename, "gtk_file_chooser_get_filename");
    }

    gchar *filename = orig_get_filename ? orig_get_filename(chooser) : NULL;
    if (filename) {
        if (g_file_test(filename, G_FILE_TEST_IS_DIR)) {
            save_last_dir(filename);
        } else {
            char *dirname = g_path_get_dirname(filename);
            if (dirname) {
                save_last_dir(dirname);
                g_free(dirname);
            }
        }
    }
    return filename;
}

GSList* gtk_file_chooser_get_filenames(GtkFileChooser *chooser) {
    if (!orig_get_filenames) {
        RESOLVE_NEXT(orig_get_filenames, "gtk_file_chooser_get_filenames");
    }

    GSList *filenames = orig_get_filenames ? orig_get_filenames(chooser) : NULL;
    if (filenames && filenames->data) {
        char *filename = (char *)filenames->data;
        if (g_file_test(filename, G_FILE_TEST_IS_DIR)) {
            save_last_dir(filename);
        } else {
            char *dirname = g_path_get_dirname(filename);
            if (dirname) {
                save_last_dir(dirname);
                g_free(dirname);
            }
        }
    }
    return filenames;
}
