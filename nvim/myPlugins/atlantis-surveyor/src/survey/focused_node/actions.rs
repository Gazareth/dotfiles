use crate::model::AtlantisNode;

use super::FocusedNode;

impl FocusedNode {
    pub(in crate::survey) fn available_actions(&self) -> Vec<&'static str> {
        let mut actions = match &self.node {
            AtlantisNode::Recognised(n) => n.available_actions().to_vec(),
            _ => vec![],
        };
        if self.comment_range.is_some() {
            actions.push("switch_to_comment");
        }
        if self.associated_statement.is_some() {
            actions.push("switch_to_statement");
        }
        actions
    }
}
