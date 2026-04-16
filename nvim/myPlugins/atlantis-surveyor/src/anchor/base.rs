use serde::{Deserialize, Serialize};

use crate::error::AtlantisError;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnchorRange {
    pub start_row: u32,
    pub start_col: u32,
    pub end_row: u32,
    pub end_col: u32,
}

/// Snapshot-style info for Atlantis consumers (Hydra, menus).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AnchorInfo {
    pub bufnr: i32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub node_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub range: Option<AnchorRange>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub text: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<String>,
}

impl AnchorInfo {
    pub fn ok(
        bufnr: i32,
        node_type: String,
        range: AnchorRange,
        text: String,
    ) -> Self {
        Self {
            bufnr,
            node_type: Some(node_type),
            range: Some(range),
            text: Some(text),
            error: None,
        }
    }

    pub fn err(bufnr: i32, err: AtlantisError) -> Self {
        Self {
            bufnr,
            node_type: None,
            range: None,
            text: None,
            error: Some(err.user_message()),
        }
    }
}
