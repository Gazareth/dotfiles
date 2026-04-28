use crate::model::supported_nodes::{HasAssignment, HasBody, HasConditionals, HasFunctions, HasParameterList};
use crate::model::lang::{NodeClass, StructureKind, SyntaxKind};

#[derive(Debug, Clone, Copy)]
pub struct Python;

impl HasFunctions for Python {}
impl HasAssignment for Python {}
impl HasConditionals for Python {}
impl HasBody for Python {}
impl HasParameterList for Python {}

crate::impl_language_syntax_map!(Python, PYTHON_KINDS, {
    "function_definition"  => NodeClass::Standard(SyntaxKind::Function),
    "assignment"           => NodeClass::Standard(SyntaxKind::Assignment),
    "augmented_assignment" => NodeClass::Standard(SyntaxKind::Assignment),
    "if_statement"         => NodeClass::Standard(SyntaxKind::Conditional),
    "parameters"           => NodeClass::Container(StructureKind::ParameterList),
    "block"                => NodeClass::Container(StructureKind::Body),
});

crate::impl_lang_node_resolver!(Python, PythonNode, PythonContainerNode);
