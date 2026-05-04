//! Tree-sitter probe using Neovim's incremental tree.

mod query;
pub(crate) mod decode;
mod types;
pub use types::*;

use crate::model::node::RawNode;
use crate::error::AtlantisError;

pub fn snapshot(
    row: u32,
    col: u32,
    target_type: Option<&str>,
    target_start: Option<(u32, u32)>,
) -> Result<NodeSnapshot, AtlantisError> {
    let d = query::call(row, col, target_type, target_start)?;

    if d.get("err").is_some() {
        return Err(AtlantisError::from_lua_err_code(&decode::str(&d, "err")?));
    }

    decode::snapshot(&d)
}
