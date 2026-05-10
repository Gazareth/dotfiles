pub(crate) mod focused_node;
mod lua;

use nvim_oxi::Dictionary;
use serde::Serialize;

use crate::error::AtlantisError;
use crate::model::node::NodeRange;
use crate::model::OutlineItem;

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
        #[serde(skip_serializing_if = "Vec::is_empty")]
        outline:           Vec<OutlineItem>,
    },
    Err { message: String },
}

impl From<FocusedNode> for SurveyResult {
    fn from(n: FocusedNode) -> Self {
        let available_actions = n.available_actions();
        Self::Ok {
            node_type: n.node_type, range: n.range, node: n.node,
            available_actions, navigation: n.navigation, outline: n.outline,
        }
    }
}

impl SurveyResult {
    pub fn generate(raw: Dictionary, _mode: Option<String>) -> Self {

        // Optional target hint: pin to a specific node in ancestry by type + position,
        // bypassing the innermost-match heuristic.
        use crate::probe::treesitter::decode;
        use nvim_oxi::conversion::FromObject;
        let target_type = decode::str(&raw, "target_node_type").ok();
        let get_u32 = |key: &str| -> Option<u32> {
            let obj = raw.get(key)?;
            i64::from_object(obj.clone()).ok().map(|i| i.max(0) as u32)
        };
        let target_hint = target_type.as_deref().and_then(|t| {
            let row = get_u32("target_start_row")?;
            let col = get_u32("target_start_col")?;
            Some((t, row, col))
        });

        match FocusedNode::from_raw(&raw, target_hint) {
            Err(e)      => Self::Err { message: e.user_message() },
            Ok(None)    => Self::Err { message: AtlantisError::UnsupportedLanguage.user_message() },
            Ok(Some(f)) => Self::from(f),
        }
    }
}
