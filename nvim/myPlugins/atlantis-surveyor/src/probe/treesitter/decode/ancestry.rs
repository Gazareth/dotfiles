//! Decode the ancestry Dictionary `{ filetype, ancestry = [...] }` passed from Lua.
//!
//! Field/child text is optional in this format (present only for single-line nodes).

use std::collections::HashMap;

use nvim_oxi::conversion::FromObject;
use nvim_oxi::{Array, Dictionary};

use crate::error::AtlantisError;
use super::super::{TsFieldNode, TsSnapshot};
use super::{str, range};

fn opt_str(d: &Dictionary, key: &str) -> String {
    d.get(key)
        .and_then(|o| nvim_oxi::String::from_object(o.clone()).ok())
        .map(|s| s.to_string())
        .unwrap_or_default()
}

fn field_node(d: &Dictionary) -> Result<TsFieldNode, AtlantisError> {
    Ok(TsFieldNode {
        node_type: str(d, "node_type")?,
        range:     range(d)?,
        text:      opt_str(d, "text"),
    })
}

fn fields(d: &Dictionary) -> HashMap<String, TsFieldNode> {
    d.get("fields")
        .and_then(|o| Dictionary::from_object(o.clone()).ok())
        .map(|fields_dict| {
            fields_dict
                .into_iter()
                .filter_map(|(key, val)| {
                    let d = Dictionary::from_object(val).ok()?;
                    Some((key.to_string(), field_node(&d).ok()?))
                })
                .collect()
        })
        .unwrap_or_default()
}

fn children(d: &Dictionary) -> Vec<TsFieldNode> {
    d.get("children")
        .and_then(|o| Array::from_object(o.clone()).ok())
        .map(|arr| {
            arr.into_iter()
                .filter_map(|val| {
                    let d = Dictionary::from_object(val).ok()?;
                    field_node(&d).ok()
                })
                .collect()
        })
        .unwrap_or_default()
}

/// Decode an ancestry Dictionary into `(filetype, ancestry)`.
///
/// `ancestry` is ordered innermost → outermost, matching the Lua collection order.
pub fn decode(d: &Dictionary) -> Result<(String, Vec<TsSnapshot>), AtlantisError> {
    let filetype = str(d, "filetype")?;
    let ancestry_obj = d.get("ancestry")
        .ok_or_else(|| AtlantisError::InvalidResponse("missing ancestry".into()))?;
    let ancestry_arr = Array::from_object(ancestry_obj.clone())
        .map_err(|e| AtlantisError::InvalidResponse(e.to_string()))?;

    let ancestry = ancestry_arr
        .into_iter()
        .filter_map(|val| {
            let entry = Dictionary::from_object(val).ok()?;
            Some(TsSnapshot {
                node_type: str(&entry, "node_type").ok()?,
                range:     range(&entry).ok()?,
                text:      String::new(),
                filetype:  filetype.clone(),
                fields:    fields(&entry),
                children:  children(&entry),
            })
        })
        .collect();

    Ok((filetype, ancestry))
}
