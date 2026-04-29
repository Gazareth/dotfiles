use crate::model::lang::CLike;

#[derive(Debug, Clone, Copy)]
pub struct JavaScript;

impl CLike for JavaScript {}

crate::impl_language_syntax_map!(JavaScript, JAVASCRIPT_KINDS, {
    construct: {
        "function_declaration"  => Function,
        "arrow_function"        => Function,
        "method_definition"     => Function,
        "assignment_expression" => Assignment,
        "variable_declarator"   => Assignment,
        "if_statement"          => Conditional,
        "call_expression"       => Call,
    },
    container: {
        "program"          => FileRoot,
        "formal_parameters" => ParameterList,
        "statement_block"  => Body,
    },
});

crate::impl_lang_node_resolver!(JavaScript, JavaScriptNode, JavaScriptContainerNode);
