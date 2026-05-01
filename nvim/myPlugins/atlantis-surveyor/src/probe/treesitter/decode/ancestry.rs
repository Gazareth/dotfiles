//! Decode the ancestry Dictionary `{ filetype, ancestry = [...] }` passed from Lua.

use nvim_oxi::conversion::FromObject;
use nvim_oxi::{Array, Dictionary};

use crate::error::AtlantisError;
use super::super::NodeOutline;
use super::{str, u32};

fn light_range(d: &Dictionary) -> Result<crate::model::node::NodeRange, AtlantisError> {
    let sr = u32(d, "start_row")?;
    let sc = u32(d, "start_col")?;
    Ok(crate::model::node::NodeRange {
        start_row: sr,
        start_col: sc,
        end_row:   u32(d, "end_row").unwrap_or(sr),
        end_col:   u32(d, "end_col").unwrap_or(sc),
    })
}

/// Decode an ancestry Dictionary into `(filetype, outlines)`.
///
/// `outlines` is ordered innermost → outermost, matching the Lua collection order.
pub fn decode(d: &Dictionary) -> Result<(String, Vec<NodeOutline>), AtlantisError> {
    let filetype = str(d, "filetype")?;
    let ancestry_obj = d.get("ancestry")
        .ok_or_else(|| AtlantisError::InvalidResponse("missing ancestry".into()))?;
    let ancestry_arr = Array::from_object(ancestry_obj.clone())
        .map_err(|e| AtlantisError::InvalidResponse(e.to_string()))?;

    let outlines = ancestry_arr
        .into_iter()
        .filter_map(|val| {
            let entry = Dictionary::from_object(val).ok()?;
            Some(NodeOutline {
                node_type: str(&entry, "node_type").ok()?,
                range:     light_range(&entry).ok()?,
            })
        })
        .collect();

    Ok((filetype, outlines))
}
