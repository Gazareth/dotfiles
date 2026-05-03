//! Tree-sitter probe using Neovim's incremental tree.

mod query;
pub(crate) mod decode;

use std::collections::HashMap;

use crate::model::node::{NodeRange, RawNode};
use crate::error::AtlantisError;

/// A single named child field returned by the query.
#[derive(Debug, Clone)]
pub struct TsFieldNode {
    pub node_type: String,
    pub range: NodeRange,
    pub text: String,
}

/// Sparse position-only ancestry entry from Lua — just enough to identify and locate a node.
#[derive(Debug, Clone)]
pub struct NodeOutline {
    pub node_type: String,
    pub range: NodeRange,
}

/// Full Tree-sitter capture — rich with fields, children, siblings, and text.
#[derive(Debug, Clone)]
pub struct TsCapture {
    pub node_type: String,
    pub range: NodeRange,
    pub text: String,
    pub fields: HashMap<String, TsFieldNode>,
    /// Unnamed named children — positional nodes like parameters, arguments.
    pub children: Vec<TsFieldNode>,
    /// All named siblings (for filtering supported navigation in the model).
    pub siblings: Vec<TsFieldNode>,
}

pub fn capture(
    row: u32,
    col: u32,
    target_type: Option<&str>,
    target_start: Option<(u32, u32)>,
) -> Result<TsCapture, AtlantisError> {
    let d = query::call(row, col, target_type, target_start)?;

    if d.get("err").is_some() {
        return Err(AtlantisError::from_lua_err_code(&decode::str(&d, "err")?));
    }

    decode::snapshot(&d)
}

impl From<&TsCapture> for RawNode {
    fn from(cap: &TsCapture) -> Self {
        RawNode {
            kind:     cap.node_type.clone(),
            text:     cap.text.clone(),
            range:    cap.range.clone(),
            fields:   cap.fields.iter().map(|(k, f)| (k.clone(), RawNode::from(f))).collect(),
            children: cap.children.iter().map(RawNode::from).collect(),
        }
    }
}

impl From<&TsFieldNode> for RawNode {
    fn from(f: &TsFieldNode) -> Self {
        RawNode {
            kind:     f.node_type.clone(),
            text:     f.text.clone(),
            range:    f.range.clone(),
            fields:   HashMap::new(),
            children: vec![],
        }
    }
}

impl From<&NodeOutline> for RawNode {
    fn from(n: &NodeOutline) -> Self {
        RawNode {
            kind:     n.node_type.clone(),
            text:     String::new(),
            range:    n.range.clone(),
            fields:   HashMap::new(),
            children: vec![],
        }
    }
}
