#define LUA_LIB
#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <fribidi/fribidi.h>

/* Fast check if text may contain RTL / Arabic UTF-8 sequences */
static bool has_rtl_content(const char *s, size_t len) {
    const unsigned char *p = (const unsigned char *)s;
    const unsigned char *end = p + len;
    while (p < end) {
        /* Arabic blocks start at U+0600..U+08FF (0xD8..0xE0), U+FB50..U+FEFC (0xEF)
           Hebrew starts at U+0590..U+05FF (0xD6..0xD7) */
        if (*p >= 0xD6 && *p <= 0xEF) {
            return true;
        }
        p++;
    }
    return false;
}

static int l_shape(lua_State *L) {
    size_t in_len = 0;
    const char *input = luaL_checklstring(L, 1, &in_len);
    if (!input || in_len == 0) {
        lua_pushstring(L, "");
        return 1;
    }

    /* Fast path for pure ASCII / LTR text */
    if (!has_rtl_content(input, in_len)) {
        lua_pushlstring(L, input, in_len);
        return 1;
    }

    FriBidiChar *logical = (FriBidiChar *)malloc((in_len + 1) * sizeof(FriBidiChar));
    if (!logical) {
        lua_pushlstring(L, input, in_len);
        return 1;
    }

    FriBidiStrIndex ulen = fribidi_charset_to_unicode(FRIBIDI_CHAR_SET_UTF8, input, (FriBidiStrIndex)in_len, logical);
    if (ulen <= 0) {
        free(logical);
        lua_pushlstring(L, input, in_len);
        return 1;
    }

    FriBidiCharType *btypes = (FriBidiCharType *)malloc(ulen * sizeof(FriBidiCharType));
    FriBidiLevel *levels = (FriBidiLevel *)malloc(ulen * sizeof(FriBidiLevel));
    FriBidiArabicProp *ar_props = (FriBidiArabicProp *)malloc(ulen * sizeof(FriBidiArabicProp));

    if (!btypes || !levels || !ar_props) {
        free(btypes);
        free(levels);
        free(ar_props);
        free(logical);
        lua_pushlstring(L, input, in_len);
        return 1;
    }

    FriBidiParType base_dir = FRIBIDI_PAR_ON; /* Auto-detect paragraph direction */

    fribidi_get_bidi_types(logical, ulen, btypes);
    FriBidiLevel max_level = fribidi_get_par_embedding_levels_ex(btypes, NULL, ulen, &base_dir, levels);
    if (max_level == 0) {
        free(btypes); free(levels); free(ar_props); free(logical);
        lua_pushlstring(L, input, in_len);
        return 1;
    }

    fribidi_get_joining_types(logical, ulen, ar_props);
    fribidi_join_arabic(btypes, ulen, levels, ar_props);
    fribidi_shape_arabic(FRIBIDI_FLAGS_DEFAULT | FRIBIDI_FLAGS_ARABIC, levels, ulen, ar_props, logical);

    FriBidiLevel reorder_res = fribidi_reorder_line(FRIBIDI_FLAGS_DEFAULT, btypes, ulen, 0, base_dir, levels, logical, NULL);
    if (reorder_res == 0) {
        free(btypes); free(levels); free(ar_props); free(logical);
        lua_pushlstring(L, input, in_len);
        return 1;
    }

    /* Allocate buffer for UTF-8 output (max 4 bytes per UTF-32 code point) */
    char *output = (char *)malloc(ulen * 4 + 1);
    if (output) {
        FriBidiStrIndex out_len = fribidi_unicode_to_charset(FRIBIDI_CHAR_SET_UTF8, logical, ulen, output);
        lua_pushlstring(L, output, out_len);
        free(output);
    } else {
        lua_pushlstring(L, input, in_len);
    }

    free(btypes);
    free(levels);
    free(ar_props);
    free(logical);
    return 1;
}

static const struct luaL_Reg bidi_funcs[] = {
    {"shape", l_shape},
    {NULL, NULL}
};

int luaopen_bidi(lua_State *L) {
    luaL_newlib(L, bidi_funcs);
    return 1;
}
