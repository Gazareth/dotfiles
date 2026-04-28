use crate::model::kinds::{StandardAssignment, StandardConditionals, StandardFunctions};
use crate::model::lang::NodeKind;

#[derive(Debug, Clone, Copy)]
pub struct Python;

impl StandardFunctions for Python {}
impl StandardAssignment for Python {}
impl StandardConditionals for Python {}

crate::impl_language_syntax_map!(Python, PYTHON_KINDS, {
    "function_definition"  => NodeKind::Function,
    "assignment"           => NodeKind::Assignment,
    "augmented_assignment" => NodeKind::Assignment,
    "if_statement"         => NodeKind::Conditional,
});

crate::impl_lang_node_resolver!(Python, PythonNode);
