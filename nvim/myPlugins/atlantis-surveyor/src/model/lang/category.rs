use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
pub enum NodeCategory {
    Function,
    Assignment,
    Conditional,
}

pub trait LanguageConfig {
    fn kinds() -> &'static phf::Map<&'static str, NodeCategory>;

    fn categorise(kind: &str) -> Option<NodeCategory> {
        Self::kinds().get(kind).copied()
    }
}
