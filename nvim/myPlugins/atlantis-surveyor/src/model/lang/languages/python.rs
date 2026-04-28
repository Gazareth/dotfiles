use crate::model::common::*;
use crate::model::lang::NodeCategory;

#[derive(Debug, Clone, Copy)]
pub struct Python;

impl StandardFunctions for Python {}
impl StandardAssignment for Python {}
impl StandardConditionals for Python {}

crate::impl_language_syntax_map!(Python, PYTHON_KINDS, {
    "function_definition"  => NodeCategory::Function,
    "assignment"           => NodeCategory::Assignment,
    "augmented_assignment" => NodeCategory::Assignment,
    "if_statement"         => NodeCategory::Conditional,
});

crate::impl_lang_node_resolver!(Python, PythonNode);
