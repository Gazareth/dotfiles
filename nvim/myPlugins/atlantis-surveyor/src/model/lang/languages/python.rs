use crate::model::NavigationTarget;
use crate::model::supported_nodes::{Assignment, HasFunctionCalls};
use crate::model::lang::Common;
use crate::model::node::{Extract, RawNode};

#[derive(Debug, Clone, Copy)]
pub struct Python;

impl Common for Python {}
impl HasFunctionCalls for Python {}

// Python assignments use `left`/`right` fields, not `name`/`value`.
impl Extract<Assignment> for Python {
    fn extract(raw: &RawNode) -> Assignment {
        Assignment {
            name:             raw.field_text("left"),
            is_local_binding: false,
            lhs:              raw.field("left").map(|r| NavigationTarget::from_raw(&r)),
            value:            raw.field("right").map(|r| NavigationTarget::from_raw(&r)),
        }
    }
}

crate::impl_language_syntax_map!(Python, PYTHON_KINDS, {
    "function_definition"       => Function,
    "assignment"                => Assignment,
    "augmented_assignment"      => Assignment,
    "if_statement"              => Conditional,
    "call"                      => Call,
    "typed_parameter"           => Parameter,
    "default_parameter"         => Parameter,
    "typed_default_parameter"   => Parameter,
    "list_splat_parameter"      => Parameter,
    "dictionary_splat_parameter" => Parameter,
    "parameter"                 => Parameter,
    "return_statement"          => ReturnStatement,
    "module"     => FileRoot,
    "parameters" => ParameterList,
    "block"      => Body,
});

crate::impl_lang_node_resolver!(Python, PythonNode);
