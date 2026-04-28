use crate::model::node::{Extract, RawNode};

/// The list of parameters in a function declaration.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ParameterList;

pub trait HasParameterList {}

impl<Lang: HasParameterList> Extract<ParameterList> for Lang {
    fn extract(_raw: &RawNode) -> ParameterList {
        ParameterList
    }
}
