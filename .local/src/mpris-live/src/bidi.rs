//! FriBidi FFI shaping and BiDi reordering for Arabic and RTL scripts.

use std::ffi::c_char;

type FriBidiChar = u32;
type FriBidiStrIndex = i32;
type FriBidiCharType = u32;
type FriBidiLevel = u8;
type FriBidiArabicProp = u8;
type FriBidiParType = u32;

const FRIBIDI_CHAR_SET_UTF8: i32 = 1;
const FRIBIDI_PAR_LTR: u32 = 1;
const FRIBIDI_FLAGS_DEFAULT: u32 = 0x00000100;
const FRIBIDI_FLAGS_ARABIC: u32 = 0x00000001;

#[link(name = "fribidi")]
extern "C" {
    fn fribidi_charset_to_unicode(
        char_set: i32,
        s: *const c_char,
        len: FriBidiStrIndex,
        us: *mut FriBidiChar,
    ) -> FriBidiStrIndex;

    fn fribidi_get_bidi_types(
        str: *const FriBidiChar,
        len: FriBidiStrIndex,
        btypes: *mut FriBidiCharType,
    );

    fn fribidi_get_par_embedding_levels_ex(
        btypes: *const FriBidiCharType,
        bracket_types: *const c_char,
        len: FriBidiStrIndex,
        pbase_dir: *mut FriBidiParType,
        embedding_levels: *mut FriBidiLevel,
    ) -> FriBidiLevel;

    fn fribidi_get_joining_types(
        str: *const FriBidiChar,
        len: FriBidiStrIndex,
        jtypes: *mut FriBidiArabicProp,
    );

    fn fribidi_join_arabic(
        btypes: *const FriBidiCharType,
        len: FriBidiStrIndex,
        embedding_levels: *const FriBidiLevel,
        ar_props: *mut FriBidiArabicProp,
    );

    fn fribidi_shape_arabic(
        flags: u32,
        embedding_levels: *const FriBidiLevel,
        len: FriBidiStrIndex,
        ar_props: *mut FriBidiArabicProp,
        str: *mut FriBidiChar,
    );

    fn fribidi_reorder_line(
        flags: u32,
        btypes: *mut FriBidiCharType,
        len: FriBidiStrIndex,
        off: FriBidiStrIndex,
        base_dir: FriBidiParType,
        embedding_levels: *mut FriBidiLevel,
        visual_str: *mut FriBidiChar,
        map: *mut FriBidiStrIndex,
    ) -> FriBidiLevel;

    fn fribidi_unicode_to_charset(
        char_set: i32,
        us: *const FriBidiChar,
        len: FriBidiStrIndex,
        s: *mut c_char,
    ) -> FriBidiStrIndex;
}

/// Returns true if the string may contain RTL or Arabic unicode code points.
pub fn has_rtl_content(text: &str) -> bool {
    text.chars().any(|c| ('\u{0600}'..='\u{08FF}').contains(&c) || ('\u{FB50}'..='\u{FEFC}').contains(&c))
}

/// Shapes and reorders text containing Arabic or RTL characters into visual Presentation Forms.
pub fn shape_bidi(text: &str) -> String {
    if !has_rtl_content(text) || text.is_empty() {
        return text.to_string();
    }

    let in_bytes = text.as_bytes();
    let in_len = in_bytes.len() as FriBidiStrIndex;

    let mut logical = vec![0u32; (in_len as usize) + 1];
    let ulen = unsafe {
        fribidi_charset_to_unicode(
            FRIBIDI_CHAR_SET_UTF8,
            in_bytes.as_ptr() as *const c_char,
            in_len,
            logical.as_mut_ptr(),
        )
    };

    if ulen <= 0 {
        return text.to_string();
    }

    let ulen_usize = ulen as usize;
    let mut btypes = vec![0u32; ulen_usize];
    let mut levels = vec![0u8; ulen_usize];
    let mut ar_props = vec![0u8; ulen_usize];
    let mut base_dir = FRIBIDI_PAR_LTR;

    unsafe {
        fribidi_get_bidi_types(logical.as_ptr(), ulen, btypes.as_mut_ptr());
        let _ = fribidi_get_par_embedding_levels_ex(
            btypes.as_ptr(),
            std::ptr::null(),
            ulen,
            &mut base_dir,
            levels.as_mut_ptr(),
        );
        fribidi_get_joining_types(logical.as_ptr(), ulen, ar_props.as_mut_ptr());
        fribidi_join_arabic(btypes.as_ptr(), ulen, levels.as_ptr(), ar_props.as_mut_ptr());
        fribidi_shape_arabic(
            FRIBIDI_FLAGS_DEFAULT | FRIBIDI_FLAGS_ARABIC,
            levels.as_ptr(),
            ulen,
            ar_props.as_mut_ptr(),
            logical.as_mut_ptr(),
        );
        let _ = fribidi_reorder_line(
            FRIBIDI_FLAGS_DEFAULT,
            btypes.as_mut_ptr(),
            ulen,
            0,
            base_dir,
            levels.as_mut_ptr(),
            logical.as_mut_ptr(),
            std::ptr::null_mut(),
        );
    }

    let mut out_bytes = vec![0u8; ulen_usize * 4 + 1];
    let out_len = unsafe {
        fribidi_unicode_to_charset(
            FRIBIDI_CHAR_SET_UTF8,
            logical.as_ptr(),
            ulen,
            out_bytes.as_mut_ptr() as *mut c_char,
        )
    };

    if out_len > 0 {
        out_bytes.truncate(out_len as usize);
        String::from_utf8(out_bytes).unwrap_or_else(|_| text.to_string())
    } else {
        text.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_shape_bidi_ascii() {
        let input = "Artist - Title";
        assert_eq!(shape_bidi(input), input);
    }

    #[test]
    fn test_shape_bidi_arabic() {
        let input = "واحد وعشرين";
        let shaped = shape_bidi(input);
        assert_ne!(shaped, input);
        assert!(has_rtl_content(&shaped));
    }

    #[test]
    fn test_shape_bidi_mixed() {
        let input = "Wegz - واحد وعشرين";
        let shaped = shape_bidi(input);
        assert!(shaped.starts_with("Wegz - "));
        assert_ne!(shaped, input);
    }
}
