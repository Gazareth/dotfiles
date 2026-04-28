use crate::model::lang::{CLike, NodeClass, StructureKind, SyntaxKind};

#[derive(Debug, Clone, Copy)]
pub struct TypeScript;

impl CLike for TypeScript {}

crate::impl_language_syntax_map!(TypeScript, TYPESCRIPT_KINDS, {
    "function_declaration"  => NodeClass::Standard(SyntaxKind::Function),
    "arrow_function"        => NodeClass::Standard(SyntaxKind::Function),
    "method_definition"     => NodeClass::Standard(SyntaxKind::Function),
    "assignment_expression" => NodeClass::Standard(SyntaxKind::Assignment),
    "variable_declarator"   => NodeClass::Standard(SyntaxKind::Assignment),
    "if_statement"          => NodeClass::Standard(SyntaxKind::Conditional),
    "formal_parameters"     => NodeClass::Container(StructureKind::ParameterList),
    "statement_block"       => NodeClass::Container(StructureKind::Body),
});

crate::impl_lang_node_resolver!(TypeScript, TypeScriptNode, TypeScriptContainerNode);
