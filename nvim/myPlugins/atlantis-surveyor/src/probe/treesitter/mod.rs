//! Tree-sitter probe using Neovim's incremental tree.

mod bridge;
mod decode;

use std::collections::HashMap;

use crate::model::node::NodeRange;
use crate::error::AtlantisError;

/// A single named child field returned by the bridge.
#[derive(Debug, Clone)]
pub struct TsFieldNode {
    pub node_type: String,
    pub range: NodeRange,
    pub text: String,
}

/// Normalised Tree-sitter capture (no Atlantis classification (yet...)).
#[derive(Debug, Clone)]
pub struct TsSnapshot {
    pub node_type: String,
    pub range: NodeRange,
    pub text: String,
    pub filetype: String,
    pub fields: HashMap<String, TsFieldNode>,
}

pub fn capture(bufnr: i32, row: u32, col: u32) -> Result<TsSnapshot, AtlantisError> {
    let d = bridge::call(bufnr, row, col)?;

    if d.get("err").is_some() {
        return Err(AtlantisError::from_lua_err_code(&decode::str(&d, "err")?));
    }

    decode::snapshot(&d)
}
