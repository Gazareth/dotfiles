use crate::model::lang::{CLike, NodeKind};

#[derive(Debug, Clone, Copy)]
pub struct TypeScript;

impl CLike for TypeScript {}

crate::impl_language_syntax_map!(TypeScript, TYPESCRIPT_KINDS, {
    "function_declaration"   => NodeKind::Function,
    "arrow_function"         => NodeKind::Function,
    "method_definition"      => NodeKind::Function,
    "assignment_expression"  => NodeKind::Assignment,
    "variable_declarator"    => NodeKind::Assignment,
    "if_statement"           => NodeKind::Conditional,
});

crate::impl_lang_node_resolver!(TypeScript, TypeScriptNode);
