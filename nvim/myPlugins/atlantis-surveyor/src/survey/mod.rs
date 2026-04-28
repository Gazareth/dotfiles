pub mod build;
mod lua;

use serde::Serialize;

use crate::error::AtlantisError;
use crate::model::resolved::{AnyContainerNode, AnyStandardNode};

/// What Atlantis knows about a node at a given buffer position.
#[derive(Debug, Serialize)]
pub struct AtlantisNode {
    pub bufnr: i32,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub node_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub range: Option<crate::model::node::NodeRange>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub text: Option<String>,
    pub variant: AtlantisVariant,
}

/// The Atlantis classification of the node at this position.
#[derive(Debug, Serialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum AtlantisVariant {
    /// A direct language construct — function, assignment, conditional, etc.
    Standard(AnyStandardNode),
    /// A structural grouping — parameter list, body, argument list, etc.
    Container(AnyContainerNode),
    /// Atlantis has no registered behaviour for this node type.
    Unrecognised,
    /// The probe failed to capture a node at this position.
    Error { message: String },
}

impl AtlantisNode {
    pub fn ok(
        bufnr: i32,
        node_type: String,
        range: crate::model::node::NodeRange,
        text: String,
        variant: AtlantisVariant,
    ) -> Self {
        Self {
            bufnr,
            node_type: Some(node_type),
            range: Some(range),
            text: Some(text),
            variant,
        }
    }

    pub fn err(bufnr: i32, err: AtlantisError) -> Self {
        Self {
            bufnr,
            node_type: None,
            range: None,
            text: None,
            variant: AtlantisVariant::Error { message: err.user_message() },
        }
    }
}
