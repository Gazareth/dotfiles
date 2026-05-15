use crate::model::AtlantisNode;

use super::FocusedNode;

impl FocusedNode {
    pub(in crate::survey) fn available_actions(&self) -> Vec<&'static str> {
        match &self.node {
            AtlantisNode::Recognised(n) => n.available_actions().to_vec(),
            _ => vec![],
        }
    }
}
