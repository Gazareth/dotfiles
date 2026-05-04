use serde::{Deserialize, Serialize};
use crate::model::node::{Extract, RawNode};
use crate::model::supported_nodes::standard::Named;
use crate::model::NavigationTarget;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionDeclaration {
    /// The function's identifier — needed for display and search.
    pub name: String,
    /// Whether declared async — affects navigation context.
    pub is_async: bool,
    /// The parameter list.
    pub parameters: Option<NavigationTarget>,
    /// The function body.
    pub body: Option<NavigationTarget>,
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
        let params = raw.field("parameters").map(NavigationTarget::container);
        let body   = raw.field("body").map(NavigationTarget::container);

        FunctionDeclaration {
            name: raw.field_text("name"),
            is_async: raw.has_field("async"),
            parameters: params,
            body,
        }
    }
}
