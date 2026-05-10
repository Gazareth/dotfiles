use serde::{Deserialize, Serialize};
use crate::model::node::{Extract, RawNode};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExpressionList {}

pub trait HasExpressionList {}

impl<Lang: HasExpressionList> Extract<ExpressionList> for Lang {
    fn extract(_raw: &RawNode) -> ExpressionList {
        ExpressionList {}
    }
}
