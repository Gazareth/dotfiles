//! Tree-sitter probe using Neovim’s incremental tree (`luaeval` in `core/node.rs`).

mod core;

use nvim_oxi::conversion::FromObject;
use nvim_oxi::Object;

use crate::anchor::AnchorRange;
use crate::error::AtlantisError;

/// Normalised capture from `core` (no Atlantis classification).
#[derive(Debug, Clone)]
pub struct TsSnapshot {
    pub node_type: String,
    pub range: AnchorRange,
    pub text: String,
}

fn obj_to_string(o: &Object) -> Result<String, AtlantisError> {
    nvim_oxi::String::from_object(o.clone())
        .map(|s| s.to_string())
        .map_err(|e| AtlantisError::InvalidResponse(e.to_string()))
}

fn obj_to_u32(o: &Object) -> Result<u32, AtlantisError> {
    let i: i64 = i64::from_object(o.clone())
        .map_err(|e| AtlantisError::InvalidResponse(e.to_string()))?;
    Ok(i.max(0) as u32)
}

pub fn capture(bufnr: i32, row: u32, col: u32) -> Result<TsSnapshot, AtlantisError> {
    let d = core::capture_raw_dictionary(bufnr, row, col)?;

    if let Some(err_o) = d.get("err") {
        let code = obj_to_string(err_o)?;
        return Err(AtlantisError::from_lua_err_code(&code));
    }

    let node_type = obj_to_string(
        d.get("node_type")
            .ok_or_else(|| AtlantisError::InvalidResponse("missing node_type".into()))?,
    )?;

    let start_row = obj_to_u32(
        d.get("start_row")
            .ok_or_else(|| AtlantisError::InvalidResponse("missing start_row".into()))?,
    )?;
    let start_col = obj_to_u32(
        d.get("start_col")
            .ok_or_else(|| AtlantisError::InvalidResponse("missing start_col".into()))?,
    )?;
    let end_row = obj_to_u32(
        d.get("end_row")
            .ok_or_else(|| AtlantisError::InvalidResponse("missing end_row".into()))?,
    )?;
    let end_col = obj_to_u32(
        d.get("end_col")
            .ok_or_else(|| AtlantisError::InvalidResponse("missing end_col".into()))?,
    )?;

    let text = obj_to_string(
        d.get("text")
            .ok_or_else(|| AtlantisError::InvalidResponse("missing text".into()))?,
    )?;

    Ok(TsSnapshot {
        node_type,
        range: AnchorRange {
            start_row,
            start_col,
            end_row,
            end_col,
        },
        text,
    })
}
