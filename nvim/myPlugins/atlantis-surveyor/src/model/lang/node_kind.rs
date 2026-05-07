/// How Atlantis classifies a Tree-sitter node — mutually exclusive.
/// A node is either a direct language construct (Standard) or a structural
/// grouping (Container); never both.
#[derive(Debug, Clone, Copy)]
pub enum NodeKind {
    Construct(ConstructNode),
    Container(ContainerNode),
}

/// The specific kind of Standard node — a direct language building block.
#[derive(Debug, Clone, Copy)]
pub enum ConstructNode {
    Function,
    Call,
    Assignment,
    Conditional,
    Parameter,
    ReturnStatement,
}

/// The specific kind of Container node — a structural grouping of child nodes.
#[derive(Debug, Clone, Copy)]
pub enum ContainerNode {
    FileRoot,
    Body,
    ParameterList,
    ArgumentList,
}

pub trait LanguageConfig {
    fn kinds() -> &'static phf::Map<&'static str, NodeKind>;

    fn node_kind(kind: &str) -> Option<NodeKind> {
        Self::kinds().get(kind).copied()
    }
}
