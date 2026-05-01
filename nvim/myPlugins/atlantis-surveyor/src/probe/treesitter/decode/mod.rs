//! Decode the raw Lua table returned by the query into typed Rust values.
//!
//! Every function takes an nvim-oxi `Dictionary` (the Rust view of a Lua table)
//! and extracts one or more fields, converting them to concrete Rust types.

pub mod ancestry;

use std::collections::HashMap;

use nvim_oxi::conversion::FromObject;
use nvim_oxi::{Array, Dictionary};

use crate::model::node::NodeRange;
use crate::error::AtlantisError;

use super::{TsFieldNode, TsCapture};

/// Pull a string value out by key; error if the key is absent or not a string.
pub fn str(d: &Dictionary, key: &str) -> Result<String, AtlantisError> {
    let obj = d.get(key)
        .ok_or_else(|| AtlantisError::InvalidResponse(format!("missing {key}")))?;
    nvim_oxi::String::from_object(obj.clone())
        .map(|s| s.to_string())
        .map_err(|e| AtlantisError::InvalidResponse(e.to_string()))
}

/// Pull an integer value out by key and clamp it to a non-negative u32.
pub fn u32(d: &Dictionary, key: &str) -> Result<u32, AtlantisError> {
    let obj = d.get(key)
        .ok_or_else(|| AtlantisError::InvalidResponse(format!("missing {key}")))?;
    let i = i64::from_object(obj.clone())
        .map_err(|e| AtlantisError::InvalidResponse(e.to_string()))?;
    Ok(i.max(0) as u32)
}

/// Parse the four positional keys every Tree-sitter node carries into a `NodeRange`.
pub fn range(d: &Dictionary) -> Result<NodeRange, AtlantisError> {
    Ok(NodeRange {
        start_row: u32(d, "start_row")?,
        start_col: u32(d, "start_col")?,
        end_row:   u32(d, "end_row")?,
        end_col:   u32(d, "end_col")?,
    })
}

/// Parse one entry from the `fields` table — a named child node.
pub fn field_node(d: &Dictionary) -> Result<TsFieldNode, AtlantisError> {
    Ok(TsFieldNode {
        node_type: str(d, "node_type")?,
        range:     range(d)?,
        text:      str(d, "text").unwrap_or_default(),
    })
}

/// Parse the `fields` table into a map of field name → child node.
/// Malformed entries are silently dropped; partial data shouldn't abort the capture.
pub fn fields(d: &Dictionary) -> HashMap<String, TsFieldNode> {
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

/// Parse the `children` array into an ordered list of unnamed named child nodes.
/// Malformed entries are silently dropped.
pub fn children(d: &Dictionary) -> Vec<TsFieldNode> {
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

/// Parse the `siblings` array into an ordered list of named sibling nodes.
pub fn siblings(d: &Dictionary) -> Vec<TsFieldNode> {
    d.get("siblings")
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

/// Assemble a complete `TsCapture` from the top-level query Dictionary.
pub fn snapshot(d: &Dictionary) -> Result<TsCapture, AtlantisError> {
    Ok(TsCapture {
        node_type: str(d, "node_type")?,
        range:     range(d)?,
        text:      str(d, "text")?,
        filetype:  str(d, "filetype").unwrap_or_default(),
        fields:    fields(d),
        children:  children(d),
        siblings:  siblings(d),
    })
}
