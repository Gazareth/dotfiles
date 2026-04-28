use crate::model::node::{Extract, RawNode};

/// A block of statements — the body of a function, loop, or conditional.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Body;

pub trait HasBody {}

impl<Lang: HasBody> Extract<Body> for Lang {
    fn extract(_raw: &RawNode) -> Body {
        Body
    }
}
