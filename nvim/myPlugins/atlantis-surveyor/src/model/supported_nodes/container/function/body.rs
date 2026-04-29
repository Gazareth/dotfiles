use crate::model::node::{Extract, RawNode};

/// A block of statements — the body of a function, loop, or conditional.
/// Holds its children as opaque RawNodes; each is resolved only when navigated to.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Body {
    pub statements: Vec<RawNode>,
}

pub trait HasFunctionBody {}

impl<Lang: HasFunctionBody> Extract<Body> for Lang {
    fn extract(raw: &RawNode) -> Body {
        Body {
            statements: raw.children.clone(),
        }
    }
}
