use crate::model::lang::{LanguageConfig, NodeKind, ContainerNode};
use crate::model::lang::languages::{JavaScript, Lua, Python, TypeScript};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Language {
    Lua,
    JavaScript,
    TypeScript,
    Python,
    Unknown,
}

pub fn detect(filetype: &str) -> Language {
    match filetype {
        "lua"        => Language::Lua,
        "javascript" => Language::JavaScript,
        "typescript" => Language::TypeScript,
        "python"     => Language::Python,
        _            => Language::Unknown,
    }
}

impl Language {
    /// Returns `Some(true)` if the node type is a file root for this language,
    /// `Some(false)` if it is recognised but is not a file root, and
    /// `None` for unknown languages where the check cannot be performed.
    pub fn is_file_root(&self, node_type: &str) -> Option<bool> {
        let class = match self {
            Language::Lua        => Lua::classify(node_type),
            Language::JavaScript => JavaScript::classify(node_type),
            Language::TypeScript => TypeScript::classify(node_type),
            Language::Python     => Python::classify(node_type),
            Language::Unknown    => return None,
        };
        Some(matches!(class, Some(NodeKind::Container(ContainerNode::FileRoot))))
    }
}
