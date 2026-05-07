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
            lhs:              raw.field("left").map(NavigationTarget::construct),
            value:            raw.field("right").map(NavigationTarget::construct),
        }
    }
}

crate::impl_language_syntax_map!(Python, PYTHON_KINDS, {
    construct: {
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
    },
    container: {
        "module"     => FileRoot,
        "parameters" => ParameterList,
        "block"      => Body,
    },
});

crate::impl_lang_node_resolver!(Python, PythonNode, PythonContainerNode);
