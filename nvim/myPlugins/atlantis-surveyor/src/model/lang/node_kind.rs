use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum NodeKind {
    Function,
    Assignment,
    Conditional,
}

pub trait LanguageConfig {
    fn kinds() -> &'static phf::Map<&'static str, NodeKind>;

    fn categorise(kind: &str) -> Option<NodeKind> {
        Self::kinds().get(kind).copied()
    }
}
