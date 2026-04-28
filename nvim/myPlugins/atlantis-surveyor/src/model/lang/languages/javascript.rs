use crate::model::lang::{CLike, NodeKind};

#[derive(Debug, Clone, Copy)]
pub struct JavaScript;

impl CLike for JavaScript {}

crate::impl_language_syntax_map!(JavaScript, JAVASCRIPT_KINDS, {
    "function_declaration"   => NodeKind::Function,
    "arrow_function"         => NodeKind::Function,
    "method_definition"      => NodeKind::Function,
    "assignment_expression"  => NodeKind::Assignment,
    "variable_declarator"    => NodeKind::Assignment,
    "if_statement"           => NodeKind::Conditional,
});

crate::impl_lang_node_resolver!(JavaScript, JavaScriptNode);
