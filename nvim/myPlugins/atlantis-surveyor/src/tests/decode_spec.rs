// Tests for the decode layer: verifies that the pure Lua-table → Rust parsing logic
// is correct independently of the Neovim query that produces the raw Dictionary.

use nvim_oxi::{Array, Dictionary, Object};

use crate::error::AtlantisError;
use crate::probe::treesitter::decode;

fn obj_str(s: &str) -> Object { Object::from(nvim_oxi::String::from(s)) }
fn obj_i64(n: i64) -> Object  { Object::from(n) }

fn dict_from<const N: usize>(pairs: [(&str, Object); N]) -> Dictionary {
    pairs.into_iter()
        .map(|(k, v)| (nvim_oxi::String::from(k), v))
        .collect()
}

fn child_dict(node_type: &str, sr: i64, sc: i64, er: i64, ec: i64, text: &str) -> Dictionary {
    dict_from([
        ("node_type", obj_str(node_type)),
        ("start_row", obj_i64(sr)),
        ("start_col", obj_i64(sc)),
        ("end_row",   obj_i64(er)),
        ("end_col",   obj_i64(ec)),
        ("text",      obj_str(text)),
    ])
}

// ── decode::str ──────────────────────────────────────────────────────────────

#[test]
fn decode_str_extracts_present_key() {
    let d = dict_from([("node_type", obj_str("function_declaration"))]);
    assert_eq!(decode::str(&d, "node_type").unwrap(), "function_declaration");
}

#[test]
fn decode_str_errors_on_missing_key() {
    let d = dict_from([("node_type", obj_str("x"))]);
    assert!(matches!(decode::str(&d, "missing"), Err(AtlantisError::InvalidResponse(_))));
}

// ── decode::snapshot ─────────────────────────────────────────────────────────

#[test]
fn decode_snapshot_parses_basic_node() {
    let param_child = Object::from(child_dict("identifier", 0, 10, 0, 11, "x"));
    let children_arr = Array::from_iter([param_child]);

    let d = dict_from([
        ("node_type", obj_str("function_declaration")),
        ("start_row", obj_i64(0)),
        ("start_col", obj_i64(0)),
        ("end_row",   obj_i64(5)),
        ("end_col",   obj_i64(3)),
        ("text",      obj_str("function foo(x) end")),
        ("fields",    Object::from(Dictionary::new())),
        ("children",  Object::from(children_arr)),
        ("siblings",  Object::from(Array::new())),
    ]);

    let snap = decode::snapshot(&d).unwrap();
    assert_eq!(snap.node_type, "function_declaration");
    assert_eq!(snap.range.start_row, 0);
    assert_eq!(snap.range.end_row, 5);
    assert_eq!(snap.children.len(), 1);
    assert_eq!(snap.children[0].node_type, "identifier");
}

// ── decode::ancestry::decode ─────────────────────────────────────────────────

#[test]
fn decode_ancestry_parses_filetype_and_outlines() {
    use crate::probe::treesitter::decode::ancestry;

    let node_entry = Object::from(dict_from([
        ("node_type",   obj_str("function_declaration")),
        ("start_row",   obj_i64(0)),
        ("start_col",   obj_i64(0)),
        ("end_row",     obj_i64(5)),
        ("end_col",     obj_i64(3)),
        ("child_count", obj_i64(3)),
    ]));
    let root_entry = Object::from(dict_from([
        ("node_type",   obj_str("chunk")),
        ("start_row",   obj_i64(0)),
        ("start_col",   obj_i64(0)),
        ("end_row",     obj_i64(10)),
        ("end_col",     obj_i64(0)),
        ("child_count", obj_i64(1)),
    ]));

    let d = dict_from([
        ("filetype", obj_str("lua")),
        ("ancestry", Object::from(Array::from_iter([node_entry, root_entry]))),
    ]);

    let (ft, outlines) = ancestry::decode(&d).unwrap();
    assert_eq!(ft, "lua");
    assert_eq!(outlines.len(), 2);
    assert_eq!(outlines[0].node_type, "function_declaration");
    assert_eq!(outlines[0].child_count, 3);
    assert_eq!(outlines[1].node_type, "chunk");
}

// ── AtlantisError::from_lua_err_code ─────────────────────────────────────────

#[test]
fn from_lua_err_code_maps_known_codes() {
    assert!(matches!(AtlantisError::from_lua_err_code("no_parser"), AtlantisError::NoParser));
    assert!(matches!(AtlantisError::from_lua_err_code("no_node"),   AtlantisError::NoNode));
    assert!(matches!(AtlantisError::from_lua_err_code("other"),     AtlantisError::InvalidResponse(_)));
}

#[test]
fn api_error_formats_message() {
    let e = AtlantisError::Api("broken pipe".into());
    assert_eq!(e.user_message(), "nvim api: broken pipe");
}
