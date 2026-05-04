use crate::tests::lua::*;

// ── assignment_statement (modern grammar) ─────────────────────────────────

#[test]
fn assignment_statement_extracts_name_from_first_child() {
    let a = lua("assignment_statement")
        .child("variable_list", "x")
        .child("expression_list", "1")
        .classify()
        .as_assignment();

    assert_eq!(a.state.name, "x");
    assert!(!a.state.is_local_binding);
}

// ── variable_declaration (modern grammar, local) ──────────────────────────

#[test]
fn variable_declaration_splits_child_text_on_equals() {
    // children[0].text is "sum = x + y" — name is the part before '=', trimmed.
    let a = lua("variable_declaration")
        .child("assignment_statement", "sum = x + y")
        .classify()
        .as_assignment();

    assert_eq!(a.state.name, "sum");
    assert!(a.state.is_local_binding);
}

#[test]
fn variable_declaration_trims_whitespace_after_split() {
    // Regression guard: "x = 1".split('=').next() is "x " — must be trimmed.
    let a = lua("variable_declaration")
        .child("assignment_statement", "x = 1")
        .classify()
        .as_assignment();

    assert_eq!(a.state.name, "x");
}

// ── local_declaration (old nvim-treesitter grammar) ───────────────────────

#[test]
fn local_declaration_uses_name_field() {
    let a = lua("local_declaration")
        .field("name", "x")
        .field("value", "42")
        .classify()
        .as_assignment();

    assert_eq!(a.state.name, "x");
    assert!(a.state.is_local_binding);
}

// ── Graceful degradation ──────────────────────────────────────────────────

#[test]
fn missing_fields_produce_empty_name() {
    for kind in ["assignment_statement", "variable_declaration", "local_declaration"] {
        let a = lua(kind).classify().as_assignment();
        assert_eq!(a.state.name, "", "empty name expected for {kind} with no fields/children");
    }
}
