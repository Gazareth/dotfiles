use crate::probe::language::{detect, Language};

#[test]
fn detect_maps_known_filetypes_to_language_variants() {
    assert_eq!(detect("lua"),        Language::Lua);
    assert_eq!(detect("javascript"), Language::JavaScript);
    assert_eq!(detect("typescript"), Language::TypeScript);
    assert_eq!(detect("python"),     Language::Python);
    assert_eq!(detect("unknown"),    Language::Unknown);
}

#[test]
fn is_file_root_returns_true_for_chunk_in_lua() {
    assert_eq!(Language::Lua.is_file_root("chunk"), Some(true));
}

#[test]
fn is_file_root_returns_false_for_non_root_nodes() {
    assert_eq!(Language::Lua.is_file_root("function_declaration"), Some(false));
}

#[test]
fn is_file_root_returns_none_for_unknown_language() {
    assert_eq!(Language::Unknown.is_file_root("chunk"), None);
}
