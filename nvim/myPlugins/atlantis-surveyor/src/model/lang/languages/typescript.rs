use crate::model::lang::CLike;

#[derive(Debug, Clone, Copy)]
pub struct TypeScript;

impl CLike for TypeScript {}

crate::impl_language_syntax_map!(TypeScript, TYPESCRIPT_KINDS, {
    construct: {
        "function_declaration"  => Function,
        "arrow_function"        => Function,
        "method_definition"     => Function,
        "assignment_expression" => Assignment,
        "variable_declarator"   => Assignment,
        "if_statement"          => Conditional,
        "call_expression"       => Call,
        "required_parameter"    => Parameter,
        "optional_parameter"    => Parameter,
        "rest_parameter"        => Parameter,
        "parameter"             => Parameter,
        "return_statement"      => ReturnStatement,
    },
    container: {
        "program"           => FileRoot,
        "formal_parameters" => ParameterList,
        "statement_block"   => Body,
    },
});

crate::impl_lang_node_resolver!(TypeScript, TypeScriptNode, TypeScriptContainerNode);
