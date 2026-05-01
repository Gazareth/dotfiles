use super::RawNode;

/// Defines how a language turns a RawNode into a typed state.
/// Blanket impls in supported_nodes/ handle shared cases; per-language overrides handle divergences.
pub trait Extract<State> {
    fn extract(raw: &RawNode) -> State;
}
