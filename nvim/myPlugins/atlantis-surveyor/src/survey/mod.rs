mod ancestry;
mod focused_node;
mod lua;
mod navigation_targets;

use nvim_oxi::Dictionary;
use serde::Serialize;

use crate::error::AtlantisError;
use crate::model::node::NodeRange;

pub use crate::model::AtlantisNode;
pub use self::navigation_targets::NavigationInfo;

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
        let available_actions = match &f.node {
            AtlantisNode::Construct(n) => n.available_actions().to_vec(),
            _ => vec![],
        };
        Self::Ok {
            node_type:         f.node_type,
            range:             f.range,
            node:              f.node,
            available_actions,
            navigation:        f.navigation,
        }
    }
}

impl SurveyResult {
    pub fn generate(raw: Dictionary) -> Self {
        match ancestry::NodeAncestry::parse(&raw) {
            Err(e)       => Self::Err { message: e.user_message() },
            Ok(ancestry) => FocusedNode::from_ancestry(ancestry)
                .map(Self::from)
                .unwrap_or_else(|| Self::Err { message: AtlantisError::UnsupportedLanguage.user_message() }),
        }
    }
}
