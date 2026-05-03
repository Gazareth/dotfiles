mod focused_node;
mod lua;

use nvim_oxi::Dictionary;
use serde::Serialize;

use crate::error::AtlantisError;
use crate::model::node::NodeRange;

pub use crate::model::AtlantisNode;
pub use self::focused_node::NavigationInfo;

use self::focused_node::FocusedNode;

/// Lua-serialised response. The `kind` field discriminates success from failure:
///   ok  — full survey result with node classification and navigation targets
///   err — a message explaining why the probe failed
#[derive(Debug, Serialize)]
#[serde(tag = "kind", rename_all = "snake_case")]
pub enum SurveyResult {
    Ok {
        node_type:         String,
        range:             NodeRange,
        node:              AtlantisNode,
        #[serde(skip_serializing_if = "Vec::is_empty")]
        available_actions: Vec<&'static str>,
        navigation:        NavigationInfo,
    },
    Err { message: String },
}

impl From<FocusedNode> for SurveyResult {
    fn from(f: FocusedNode) -> Self {
        let available_actions = f.available_actions();
        Self::Ok {
            node_type:         f.node_type,
            range:             f.range,
            available_actions,
            node:              f.node,
            navigation:        f.navigation,
        }
    }
}

impl SurveyResult {
    pub fn generate(raw: Dictionary) -> Self {
        match FocusedNode::from_raw(&raw) {
            Err(e)      => Self::Err { message: e.user_message() },
            Ok(None)    => Self::Err { message: AtlantisError::UnsupportedLanguage.user_message() },
            Ok(Some(f)) => Self::from(f),
        }
    }
}
