use crate::tests::lua::*;

#[test]
fn extracts_condition_and_consequence() {
    let c = lua("if_statement")
        .field("condition",   "sum > 0")
        .field("consequence", "return sum")
        .classify()
        .as_conditional();

    assert_eq!(c.state.condition.text,   "sum > 0");
    assert_eq!(c.state.consequence.text, "return sum");
    assert!(c.state.alternate.is_none());
}

#[test]
fn if_else_extracts_alternate() {
    let c = lua("if_statement")
        .field("condition",   "x > 0")
        .field("consequence", "return x")
        .field("alternative", "return 0")
        .classify()
        .as_conditional();

    assert_eq!(c.state.alternate.as_ref().unwrap().text, "return 0");
}
