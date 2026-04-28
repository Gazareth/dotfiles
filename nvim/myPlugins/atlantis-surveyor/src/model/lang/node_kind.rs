/// How Atlantis classifies a Tree-sitter node — mutually exclusive.
/// A node is either a direct language construct (Standard) or a structural
/// grouping (Container); never both.
#[derive(Debug, Clone, Copy)]
pub enum NodeClass {
    Standard(SyntaxKind),
    Container(StructureKind),
}

/// The specific kind of Standard node — a direct language building block.
#[derive(Debug, Clone, Copy)]
pub enum SyntaxKind {
    Function,
    Assignment,
    Conditional,
}

/// The specific kind of Container node — a structural grouping of child nodes.
#[derive(Debug, Clone, Copy)]
pub enum StructureKind {
    Body,
    ParameterList,
    ArgumentList,
}

pub trait LanguageConfig {
    fn kinds() -> &'static phf::Map<&'static str, NodeClass>;

    fn classify(kind: &str) -> Option<NodeClass> {
        Self::kinds().get(kind).copied()
    }
}
