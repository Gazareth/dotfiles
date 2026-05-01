use serde::{Deserialize, Serialize};
use crate::model::node::{Extract, RawNode};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConditionalStatement {
    /// The condition expression. Opaque — resolved if navigated into.
    pub condition: RawNode,
    /// The block that runs when the condition passes.
    pub consequence: RawNode,
    /// The else / elif branch, if present.
    pub alternate: Option<RawNode>,
}

/// Languages where conditionals follow: `if (condition) { consequent } [else { alternate }]`
pub trait HasConditionals {}

impl<Lang: HasConditionals> Extract<ConditionalStatement> for Lang {
    fn extract(raw: &RawNode) -> ConditionalStatement {
        ConditionalStatement {
            condition: raw.field("condition").cloned().unwrap_or_else(|| raw.placeholder("condition")),
            consequence: raw.field("consequence").cloned().unwrap_or_else(|| raw.placeholder("consequence")),
            alternate: raw.field("alternative").cloned(),
        }
    }
}
