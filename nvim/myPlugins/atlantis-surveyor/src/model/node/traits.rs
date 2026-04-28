use super::RawNode;

/// Defines how a language turns a RawNode into a typed state.
/// Blanket impls in supported_nodes/ handle shared cases; per-language overrides handle divergences.
pub trait Extract<State> {
    fn extract(raw: &RawNode) -> State;
}

/// Common navigation contract for both Standard and Container nodes.
/// Reaches up to the parent Standard node to enumerate its named fields
/// as sibling entries — used to populate the navigation column in the UI.
/// Implementations are added when cursor/navigation is built.
pub trait HasSiblings {
    fn sibling_context(&self, parent: &RawNode) -> Vec<SiblingEntry>;
}

pub struct SiblingEntry {
    pub field_name: String,
    pub raw: RawNode,
}
