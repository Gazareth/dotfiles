use serde::{Deserialize, Serialize};
use crate::model::node::{Extract, RawNode};
use crate::model::supported_nodes::standard::Named;
use crate::model::NavigationTarget;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionCall {
    /// The name of the function being called — needed for display.
    pub name: String,
    /// The range of the function being called — used for outline suppression.
    pub name_range: Option<crate::model::node::NodeRange>,
    /// The argument list.
    pub parameters: Option<NavigationTarget>,
}

impl Named for FunctionCall {
    fn name(&self) -> &str {
        &self.name
    }
}

/// Languages where function calls follow: `function(arguments)`
/// with a `function` field for the callee and `arguments` for the arg list.
/// Languages with different field names (e.g. Lua) override Extract<FunctionCall> directly.
pub trait HasFunctionCalls {}

impl<Lang: HasFunctionCalls> Extract<FunctionCall> for Lang {
    fn extract(raw: &RawNode) -> FunctionCall {
        FunctionCall {
            name:       raw.field_text("function"),
            name_range: raw.field("function").map(|r| r.range.clone()),
            parameters: raw.field("arguments").map(|r| NavigationTarget::with_key(&r, "a")),
        }
    }
}
