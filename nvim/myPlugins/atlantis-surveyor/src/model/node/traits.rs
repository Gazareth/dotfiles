use super::RawNode;

/// Defines how a language turns a RawNode into a typed state.
/// Blanket impls in common.rs handle shared cases.
/// Per-language overrides in each lang module handle divergences.
pub trait Extract<State> {
    fn extract(raw: &RawNode) -> State;
}
