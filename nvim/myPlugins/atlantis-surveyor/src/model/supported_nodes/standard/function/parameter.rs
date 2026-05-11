use crate::model::node::{Extract, RawNode};

/// A single parameter in a function declaration.
/// The name is the text of the identifier node itself.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Parameter {
    pub name: String,
}

pub trait HasParameter {}

impl crate::model::supported_nodes::standard::Named for Parameter {
    fn name(&self) -> &str {
        &self.name
    }
}

impl<Lang: HasParameter> Extract<Parameter> for Lang {
    fn extract(raw: &RawNode) -> Parameter {
        Parameter { name: raw.text.clone() }
    }
}
