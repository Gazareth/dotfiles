use crate::tests::lua::*;

// ── function_declaration ──────────────────────────────────────────────────

#[test]
fn extracts_name() {
    let f = lua("function_declaration")
        .field("name", "add")
        .field("parameters", "(x, y)")
        .classify()
        .as_function();

    assert_eq!(f.state.name, "add");
    assert!(!f.state.is_async);
}

#[test]
fn async_field_presence_sets_is_async() {
    // is_async is driven by `raw.has_field("async")` — presence, not value.
    let f = lua("function_declaration")
        .field("name", "fetch")
        .field("async", "async")
        .classify()
        .as_function();

    assert_eq!(f.state.name, "fetch");
    assert!(f.state.is_async);
}

// ── local_function ────────────────────────────────────────────────────────

#[test]
fn local_function_extracts_name() {
    let f = lua("local_function")
        .field("name", "helper")
        .classify()
        .as_function();

    assert_eq!(f.state.name, "helper");
}

// ── Graceful degradation ──────────────────────────────────────────────────

#[test]
fn missing_name_field_produces_empty_string() {
    let f = lua("function_declaration").classify().as_function();
    assert_eq!(f.state.name, "");
}
