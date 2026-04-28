use crate::model::node::{Extract, RawNode};
use crate::model::supported_nodes::standard::function::{HasParameter, Parameter};

/// The list of parameters in a function declaration.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ParameterList {
    pub parameters: Vec<Parameter>,
}

/// Supertrait: a language that has parameter lists necessarily has parameters.
pub trait HasParameterList: HasParameter {}

impl<Lang: HasParameterList> Extract<ParameterList> for Lang {
    fn extract(raw: &RawNode) -> ParameterList {
        ParameterList {
            parameters: raw.children.iter()
                .map(|child| <Lang as Extract<Parameter>>::extract(child))
                .collect(),
        }
    }
}
