use crate::model::AtlantisNode;
use crate::model::lang::{LanguageConfig, NodeKind, ContainerNode};
use crate::model::lang::languages::{JavaScript, Lua, Python, TypeScript};
use crate::model::node::RawNode;
use crate::probe::treesitter::NodeOutline;

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
            Language::Lua        => Lua::node_kind(node_type),
            Language::JavaScript => JavaScript::node_kind(node_type),
            Language::TypeScript => TypeScript::node_kind(node_type),
            Language::Python     => Python::node_kind(node_type),
            Language::Unknown    => return None,
        };
        Some(matches!(class, Some(NodeKind::Container(ContainerNode::FileRoot))))
    }

    /// Classify a raw node in this language, using the optional parent outline
    /// to resolve ambiguous nodes.
    pub fn classify(&self, raw: RawNode, parent: Option<&NodeOutline>) -> AtlantisNode {
        let base = AtlantisNode::from_raw(raw.clone(), self);
        match self {
            // Lua: a bare identifier inside a parameter list is a parameter.
            // Other languages have distinct node kinds for their parameters.
            Language::Lua => {
                if matches!(base, AtlantisNode::Unrecognised) && raw.kind == "identifier" {
                    if let Some(p) = parent {
                        if matches!(Lua::node_kind(&p.node_type),
                            Some(NodeKind::Container(ContainerNode::ParameterList))) {
                            let mut refined = raw;
                            refined.kind = "parameter".to_string();
                            return AtlantisNode::from_raw(refined, self);
                        }
                    }
                }
                base
            }
            _ => base,
        }
    }
}
