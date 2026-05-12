/// How Atlantis classifies a Tree-sitter node — mutually exclusive.
/// A node is a unified construct that may have actions and navigable children.
#[derive(Debug, Clone, Copy)]
pub enum NodeKind {
    Function,
    Call,
    Assignment,
    Conditional,
    Parameter,
    ReturnStatement,
    FileRoot,
    Body,
    ParameterList,
    ArgumentList,
    ExpressionList,
}

impl NodeKind {
    /// Homogeneous selection container.
    /// With ≤ 1 named child the node and its unrecognised children are Unrecognised
    /// (nothing to select — walker climbs). With ≥ 2 named children the node is
    /// Recognised and each unrecognised child inside is a Leaf (individually focusable).
    /// Also used by the hint-navigation outermost-match path in find_focus_idx.
    pub fn is_transparent(&self) -> bool {
        matches!(self,
            NodeKind::ParameterList  |
            NodeKind::ArgumentList   |
            NodeKind::ExpressionList |
            NodeKind::Body
        )
    }
}

pub trait LanguageConfig {
    fn kinds() -> &'static phf::Map<&'static str, NodeKind>;

    fn node_kind(kind: &str) -> Option<NodeKind> {
        Self::kinds().get(kind).copied()
    }
}
