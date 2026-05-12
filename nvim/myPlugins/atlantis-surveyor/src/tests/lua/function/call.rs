use crate::tests::lua::*;

// Lua-specific: callee is in the `name` field, not `function` (the standard default).

#[test]
fn lua_uses_name_field_for_callee() {
    let k = lua("function_call")
        .field_text("name", "print")
        .field_text("args", "(\"hello\")")
        .classify()
        .as_call();

    assert_eq!(k.state.name, "print");
}

#[test]
fn missing_name_field_produces_empty_string() {
    let k = lua("function_call").classify().as_call();
    assert_eq!(k.state.name, "");
}
