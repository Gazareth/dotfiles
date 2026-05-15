#[cfg(not(test))]
use crate::model::AtlantisNode;

use super::FocusedNode;

impl FocusedNode {
    #[cfg(not(test))]
    pub(in crate::survey) fn available_actions(&self) -> Vec<&'static str> {
        match &self.node {
            AtlantisNode::Recognised(n) => n.available_actions().to_vec(),
            _ => vec![],
        }
    }
}
