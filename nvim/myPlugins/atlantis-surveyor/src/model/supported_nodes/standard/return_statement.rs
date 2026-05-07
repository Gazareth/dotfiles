use serde::{Deserialize, Serialize};
use crate::model::node::{Extract, RawNode};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ReturnStatement;

pub trait HasReturnStatement {}

impl<Lang: HasReturnStatement> Extract<ReturnStatement> for Lang {
    fn extract(_raw: &RawNode) -> ReturnStatement {
        ReturnStatement
    }
}
