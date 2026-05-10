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
    /// Returns true if this node kind should be skipped during ancestry traversal
    /// when it is the sole child of a container, effectively making it transparent.
    pub fn is_transparent(&self) -> bool {
        match self {
            NodeKind::FileRoot => true,
            NodeKind::Body => true,
            NodeKind::ParameterList => true,
            NodeKind::ExpressionList => true,
            NodeKind::ArgumentList => true,
            NodeKind::Function => false,
            NodeKind::Call => false,
            NodeKind::Assignment => false,
            NodeKind::Conditional => false,
            NodeKind::Parameter => false,
            NodeKind::ReturnStatement => false,
        }
    }
}

pub trait LanguageConfig {
    fn kinds() -> &'static phf::Map<&'static str, NodeKind>;

    fn node_kind(kind: &str) -> Option<NodeKind> {
        Self::kinds().get(kind).copied()
    }
}
