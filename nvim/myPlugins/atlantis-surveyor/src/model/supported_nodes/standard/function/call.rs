use serde::{Deserialize, Serialize};
use crate::model::node::{Extract, RawNode};
use crate::model::supported_nodes::standard::Named;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionCall {
    /// The name of the function being called — needed for display.
    pub name: String,
    /// The argument list. Opaque until the user drills in.
    pub arguments: RawNode,
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
            name: raw.field_text("function"),
            arguments: raw.field("arguments").cloned().unwrap_or_else(|| raw.placeholder("arguments")),
        }
    }
}
