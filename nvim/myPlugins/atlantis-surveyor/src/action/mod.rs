/// Returns the action keys available for a resolved construct node.
/// Implemented by the language-specific node enums via `impl_lang_node_resolver!`.
pub trait ConstructActions: std::fmt::Debug + Send + Sync {
    /// The specific node type as reported by Tree-sitter.
    fn node_type_name(&self) -> &'static str;

    /// List of semantic actions available for this node.
    fn available_actions(&self) -> &'static [&'static str];

    /// Returns (range, hint_key) pairs for NavigationTarget fields that carry a pinned hotkey.
    /// Used to stamp matching OutlineItems with their preferred UI key.
    fn keyed_outline_hints(&self) -> Vec<(crate::model::node::NodeRange, &'static str)>;

    /// Returns the ranges of any children that should be suppressed from the outline.
    /// Used for nodes like function names where the parent already provides full interaction.
    fn outline_exceptions(&self) -> Vec<crate::model::node::NodeRange> {
        vec![]
    }
}
