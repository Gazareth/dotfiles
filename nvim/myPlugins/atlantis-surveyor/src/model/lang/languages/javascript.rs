use crate::model::common::*;
use crate::model::lang::NodeCategory;

#[derive(Debug, Clone, Copy)]
pub struct JavaScript;

impl CLike for JavaScript {}

crate::impl_language_syntax_map!(JavaScript, JAVASCRIPT_KINDS, {
    "function_declaration"   => NodeCategory::Function,
    "arrow_function"         => NodeCategory::Function,
    "method_definition"      => NodeCategory::Function,
    "assignment_expression"  => NodeCategory::Assignment,
    "variable_declarator"    => NodeCategory::Assignment,
    "if_statement"           => NodeCategory::Conditional,
});

crate::impl_lang_node_resolver!(JavaScript, JavaScriptNode);
