use crate::model::AtlantisNode;

use super::FocusedNode;

impl<S> FocusedNode<S> {
    pub(in crate::survey) fn available_actions(&self) -> Vec<&'static str> {
        match &self.node {
            AtlantisNode::Construct(n) => n.available_actions().to_vec(),
            _ => vec![],
        }
    }
}
