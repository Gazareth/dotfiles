use crate::model::common::*;
use crate::model::lang::NodeCategory;

#[derive(Debug, Clone, Copy)]
pub struct TypeScript;

impl CLike for TypeScript {}

crate::impl_language_syntax_map!(TypeScript, TYPESCRIPT_KINDS, {
    "function_declaration"   => NodeCategory::Function,
    "arrow_function"         => NodeCategory::Function,
    "method_definition"      => NodeCategory::Function,
    "assignment_expression"  => NodeCategory::Assignment,
    "variable_declarator"    => NodeCategory::Assignment,
    "if_statement"           => NodeCategory::Conditional,
});

crate::impl_lang_node_resolver!(TypeScript, TypeScriptNode);
