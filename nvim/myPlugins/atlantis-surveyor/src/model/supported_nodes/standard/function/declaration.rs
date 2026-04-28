use serde::{Deserialize, Serialize};
use crate::model::node::{Extract, RawNode};
use crate::model::supported_nodes::standard::Named;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionDeclaration {
    /// The function's identifier — needed for display and search.
    pub name: String,
    /// Whether declared async — affects navigation context.
    pub is_async: bool,
    /// The parameter list. Opaque until the user drills in.
    pub parameters: RawNode,
    /// The function body. Opaque until the user drills in.
    pub body: RawNode,
}

impl Named for FunctionDeclaration {
    fn name(&self) -> &str {
        &self.name
    }
}

/// Languages where functions follow: `[async] function name(...) { body }`
/// or close enough that the same field names apply.
pub trait HasFunctions {}

impl<Lang: HasFunctions> Extract<FunctionDeclaration> for Lang {
    fn extract(raw: &RawNode) -> FunctionDeclaration {
        FunctionDeclaration {
            name: raw.field_text("name"),
            is_async: raw.has_field("async"),
            // Body and parameters are kept as opaque RawNodes.
            // Atlantis resolves them fresh if the user navigates in.
            parameters: raw.field("parameters").cloned().unwrap_or_else(|| raw.placeholder("parameters")),
            body: raw.field("body").cloned().unwrap_or_else(|| raw.placeholder("body")),
        }
    }
}
