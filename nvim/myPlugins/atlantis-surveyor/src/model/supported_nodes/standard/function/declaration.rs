use serde::{Deserialize, Serialize};
use crate::model::node::{Extract, RawNode};
use crate::model::NavigationTarget;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionDeclaration {
    /// The function's identifier — needed for display and search.
    pub name: String,
    /// The range of the function's identifier — used for outline suppression.
    pub name_range: Option<crate::model::node::NodeRange>,
    /// Whether declared async — affects navigation context.
    pub is_async: bool,
    /// The parameter list.
    pub parameters: Option<NavigationTarget>,
    /// The function body.
    pub body: Option<NavigationTarget>,
}

/// Languages where functions follow: `[async] function name(...) { body }`
/// or close enough that the same field names apply.
pub trait HasStandardFunctions {}

impl<Lang: HasStandardFunctions> Extract<FunctionDeclaration> for Lang {
    fn extract(raw: &RawNode) -> FunctionDeclaration {
        let params = raw.field("parameters").map(|r| NavigationTarget::with_key(r, "p"));
        let body   = raw.field("body").map(|r| NavigationTarget::with_key(r, "b"));

        FunctionDeclaration {
            name: raw.field_text("name"),
            name_range: raw.field("name").map(|r| r.range.clone()),
            is_async: raw.has_field("async"),
            parameters: params,
            body,
        }
    }
}
