use crate::tests::lua::*;


#[test]
fn extracts_condition_and_consequence() {
    let c = lua("if_statement")
        .field("condition",   "sum > 0")
        .field("consequence", "return sum")
        .classify()
        .as_conditional();

    assert_eq!(c.state.condition.text, "sum > 0");

    let consequence = c.state.consequence.as_ref().expect("consequence should be Some");
    assert_eq!(consequence.node_type, "consequence");

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

    let alternate = c.state.alternate.as_ref().expect("alternate should be Some");
    assert_eq!(alternate.node_type, "alternative");
}
