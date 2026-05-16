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

    /// True for node types that are atomic value literals in any supported language —
    /// `true`, `false`, `nil`, `null`, `none`. These are always focusable as Leaf nodes
    /// even when they are the sole child of a translucent parent.
    fn is_literal_leaf_kind(kind: &str) -> bool {
        matches!(kind, "true" | "false" | "nil" | "null" | "none")
    }

    /// Classify a raw node in this language, using the optional parent outline
    /// to resolve ambiguous nodes.
    pub fn classify(&self, raw: RawNode, parent: Option<&NodeOutline>) -> AtlantisNode {
        let base = AtlantisNode::from_raw(raw.clone(), self);

        // Guard A — unrecognised child of a translucent parent.
        if matches!(base, AtlantisNode::Unrecognised) {
            if let Some(p) = parent {
                if let Some(pk) = self.node_kind_for(&p.node_type) {
                    if pk.is_translucent() {
                        if p.child_count <= 1 {
                            // Allow Lua identifier → Parameter reclassification even inside a
                            // transparent (≤1 child) list, so a single parameter is focusable.
                            if let Language::Lua = self {
                                if raw.kind == "identifier"
                                    && matches!(pk, NodeKind::ParameterList)
                                {
                                    let mut refined = raw;
                                    refined.kind = "parameter".to_string();
                                    return AtlantisNode::from_raw(refined, self);
                                }
                            }
                            // Literal tokens are intrinsically meaningful — stop here as Leaf
                            // rather than climbing to the parent assignment/expression.
                            if Self::is_literal_leaf_kind(&raw.kind) {
                                return AtlantisNode::Leaf;
                            }
                            return AtlantisNode::Unrecognised;
                        }
                        return AtlantisNode::Leaf;
                    }
                }
            }
        }

        // Guard B — translucent node with ≤1 child → transparent: no selection possible.
        if raw.child_count <= 1 {
            if let Some(k) = self.node_kind_for(&raw.kind) {
                if k.is_translucent() {
                    return AtlantisNode::Unrecognised;
                }
            }
        }

        // Guard C — ExpressionList node directly inside a parent of the same node_type
        // → transparent: the inner node is an intermediate in the chain, climbed through
        // regardless of child count. This makes nested binary_expression chains flatten
        // naturally without bespoke sibling logic.
        if let Some(NodeKind::ExpressionList) = self.node_kind_for(&raw.kind) {
            if parent.is_some_and(|p| p.node_type == raw.kind) {
                return AtlantisNode::Unrecognised;
            }
        }

        base
    }
}
