use serde::{Deserialize, Serialize};
use crate::model::node::{Extract, RawNode};

/// A loop construct — for / while / repeat. Opaque: the outer node carries
/// classification, navigation drills into children via the standard pipeline.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LoopStatement;

pub trait HasLoops {}

impl<Lang: HasLoops> Extract<LoopStatement> for Lang {
    fn extract(_raw: &RawNode) -> LoopStatement {
        LoopStatement
    }
}
