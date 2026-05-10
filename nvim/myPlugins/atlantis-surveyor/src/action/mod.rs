/// Returns the action keys available for a resolved construct node.
/// Implemented by the language-specific node enums via `impl_lang_node_resolver!`.
pub trait ConstructActions {
    fn available_actions(&self) -> &'static [&'static str];
    /// Returns (range, hint_key) pairs for NavigationTarget fields that carry a pinned hotkey.
    /// Used to stamp matching OutlineItems with their preferred UI key.
    fn keyed_outline_hints(&self) -> Vec<(crate::model::node::NodeRange, &'static str)>;
}
