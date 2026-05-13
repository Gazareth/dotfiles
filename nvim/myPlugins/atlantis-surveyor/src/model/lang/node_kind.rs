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
    /// True for node kinds whose focusability depends on context (translucent kinds).
    /// A translucent node becomes transparent — invisible, climbed through — when
    /// Guard B fires (≤1 child) or Guard C fires (same-type ExpressionList nesting).
    /// With ≥2 children it is opaque: Recognised, with each unrecognised child a Leaf.
    pub fn is_translucent(&self) -> bool {
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
