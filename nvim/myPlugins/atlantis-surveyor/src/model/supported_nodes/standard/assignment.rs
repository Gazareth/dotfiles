use serde::{Deserialize, Serialize};
use crate::model::node::{Extract, RawNode};
use crate::model::NavigationTarget;
use super::Named;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Assignment {
    /// The name being assigned to — needed for display and search.
    pub name: String,
    /// Whether this introduces a new locally-scoped binding (e.g. Lua's `local`).
    pub is_local_binding: bool,
    /// Navigation target for the left-hand side (variable name / pattern).
    pub lhs: Option<NavigationTarget>,
    /// Navigation target for the right-hand side expression.
    pub value: Option<NavigationTarget>,
}

impl Named for Assignment {
    fn name(&self) -> &str {
        &self.name
    }
}

/// Languages where assignment follows: `name = value` with no scoping keyword.
pub trait HasAssignment {}

impl<Lang: HasAssignment> Extract<Assignment> for Lang {
    fn extract(raw: &RawNode) -> Assignment {
        Assignment {
            name:             raw.field_text("name"),
            is_local_binding: false,
            lhs:              raw.field("name").map(NavigationTarget::construct),
            value:            raw.field("value").map(NavigationTarget::construct),
        }
    }
}
