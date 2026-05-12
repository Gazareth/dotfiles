use crate::model::AtlantisNode;
use crate::model::lang::{LanguageConfig, NodeKind};
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
    pub(crate) fn node_kind_for(&self, node_type: &str) -> Option<NodeKind> {
        match self {
            Language::Lua        => Lua::node_kind(node_type),
            Language::JavaScript => JavaScript::node_kind(node_type),
            Language::TypeScript => TypeScript::node_kind(node_type),
            Language::Python     => Python::node_kind(node_type),
            Language::Unknown    => None,
        }
    }

    pub fn is_transparent(&self, node_type: &str) -> bool {
        self.node_kind_for(node_type).map_or(false, |k| k.is_transparent())
    }

    /// Returns `Some(true)` if the node type is a file root for this language,
    /// `Some(false)` if it is recognised but is not a file root, and
    /// `None` for unknown languages where the check cannot be performed.
    pub fn is_file_root(&self, node_type: &str) -> Option<bool> {
        if matches!(self, Language::Unknown) { return None; }
        Some(matches!(self.node_kind_for(node_type), Some(NodeKind::FileRoot)))
    }

    pub fn is_function_construct(&self, node_type: &str) -> bool {
        matches!(self.node_kind_for(node_type), Some(NodeKind::Function))
    }

    pub fn is_body_container(&self, node_type: &str) -> bool {
        matches!(self.node_kind_for(node_type), Some(NodeKind::Body))
    }

    /// Classify a raw node in this language, using the optional parent outline
    /// to resolve ambiguous nodes.
    pub fn classify(&self, raw: RawNode, parent: Option<&NodeOutline>) -> AtlantisNode {
        let base = AtlantisNode::from_raw(raw.clone(), self);

        // Guard A — unrecognised child of a transparent parent.
        if matches!(base, AtlantisNode::Unrecognised) {
            if let Some(p) = parent {
                if let Some(pk) = self.node_kind_for(&p.node_type) {
                    if pk.is_transparent() {
                        if p.child_count <= 1 {
                            return AtlantisNode::Unrecognised;
                        }
                        return AtlantisNode::Leaf;
                    }
                }
            }
        }

        // Guard B — transparent node itself with ≤ 1 child: no selection possible.
        if raw.child_count <= 1 {
            if let Some(k) = self.node_kind_for(&raw.kind) {
                if k.is_transparent() {
                    return AtlantisNode::Unrecognised;
                }
            }
        }

        match self {
            // Lua: a bare identifier inside a parameter list is a parameter.
            // Other languages have distinct node kinds for their parameters.
            Language::Lua => {
                if matches!(base, AtlantisNode::Unrecognised) && raw.kind == "identifier" {
                    if let Some(p) = parent {
                        if matches!(Lua::node_kind(&p.node_type), Some(NodeKind::ParameterList)) {
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
