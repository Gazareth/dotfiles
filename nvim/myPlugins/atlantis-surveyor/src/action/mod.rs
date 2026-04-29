/// Returns the action keys available for a resolved construct node.
/// Implemented by the language-specific node enums via `impl_lang_node_resolver!`.
pub trait ConstructActions {
    fn available_actions(&self) -> &'static [&'static str];
}
