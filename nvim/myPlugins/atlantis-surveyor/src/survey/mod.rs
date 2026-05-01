mod ancestry;
mod lua;

use nvim_oxi::Dictionary;
use serde::Serialize;

use crate::error::AtlantisError;
use crate::model::node::NodeRange;
use crate::probe::treesitter::{self, NodeOutline, TsFieldNode};
use crate::model::node::RawNode;

pub use self::ancestry::node::AtlantisNode;

/// Lua-serialised response — focus node plus optional pre-resolved ancestor.
#[derive(Debug, Serialize)]
pub struct SurveyResult {
    pub bufnr: i32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub node_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub range: Option<NodeRange>,
    pub node: AtlantisNode,
    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub available_actions: Vec<&'static str>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub navigation: Option<NavigationInfo>,
}

/// Pointer to a navigation destination — enough to jump to and re-probe if needed.
#[derive(Debug, Serialize, Clone)]
pub struct NavigationTarget {
    pub node_type: String,
    pub range: NodeRange,
}

/// Pre-computed navigation targets for a resolved node.
#[derive(Debug, Serialize)]
pub struct NavigationInfo {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parent: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub top_level: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prev_sibling: Option<NavigationTarget>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub next_sibling: Option<NavigationTarget>,
    pub is_at_top: bool,
}

impl From<&NodeOutline> for NavigationTarget {
    fn from(n: &NodeOutline) -> Self {
        Self { node_type: n.node_type.clone(), range: n.range.clone() }
    }
}

impl From<&TsFieldNode> for NavigationTarget {
    fn from(f: &TsFieldNode) -> Self {
        Self { node_type: f.node_type.clone(), range: f.range.clone() }
    }
}

impl From<ancestry::resolved::ResolvedNode> for SurveyResult {
    fn from(rn: ancestry::resolved::ResolvedNode) -> Self {
        Self::ok(rn.bufnr, rn.node_type, rn.range, rn.node, Some(rn.navigation))
    }
}

impl SurveyResult {
    /// Probe a single position without ancestry context — no navigation info.
    pub fn at_position(
        bufnr:        i32,
        row:          u32,
        col:          u32,
        target_type:  Option<&str>,
        target_start: Option<(u32, u32)>,
    ) -> Vec<Self> {
        match treesitter::capture(bufnr, row, col, target_type, target_start) {
            Ok(cap) => {
                let node = ancestry::NodeAncestry::for_language(&cap.filetype)
                    .resolve_node(RawNode::from(&cap));
                vec![Self::ok(bufnr, cap.node_type, cap.range, node, None)]
            }
            Err(e) => vec![Self::err(bufnr, e)],
        }
    }

    /// Resolve from a pre-collected ancestry dict — returns focus + optional pre-resolved ancestor.
    pub fn generate(bufnr: i32, raw: Dictionary) -> Vec<Self> {
        match ancestry::NodeAncestry::decode(bufnr, &raw) {
            Ok(resolved_nodes) => resolved_nodes.into_iter().map(Self::from).collect(),
            Err(e) => vec![Self::err(bufnr, e)],
        }
    }

    pub fn ok(
        bufnr:      i32,
        node_type:  String,
        range:      NodeRange,
        node:       AtlantisNode,
        navigation: Option<NavigationInfo>,
    ) -> Self {
        let available_actions = match &node {
            AtlantisNode::Construct(n) => n.available_actions().to_vec(),
            _ => vec![],
        };
        Self {
            bufnr,
            node_type: Some(node_type),
            range: Some(range),
            node,
            available_actions,
            navigation,
        }
    }

    pub fn err(bufnr: i32, err: AtlantisError) -> Self {
        Self {
            bufnr,
            node_type: None,
            range: None,
            node: AtlantisNode::Error { message: err.user_message() },
            available_actions: vec![],
            navigation: None,
        }
    }
}
