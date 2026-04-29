use crate::model::supported_nodes::{Assignment, FunctionCall};
use crate::model::lang::Common;
use crate::model::node::{Extract, RawNode};

#[derive(Debug, Clone, Copy)]
pub struct Lua;

impl Common for Lua {}

impl Extract<FunctionCall> for Lua {
    fn extract(raw: &RawNode) -> FunctionCall {
        FunctionCall {
            // Lua function_call uses `name`, not `function`, for the callee field.
            name: raw.field_text("name"),
            arguments: raw.field("args").cloned().unwrap_or_else(|| raw.placeholder("args")),
        }
    }
}

impl Extract<Assignment> for Lua {
    fn extract(raw: &RawNode) -> Assignment {
        Assignment {
            // Lua assignment statements use `name`, not `variable`, for the assignee field.
            name: raw.field_text("name"),
            is_local_binding: raw.kind == "local_declaration",
            value: raw.field("value").cloned().unwrap_or_else(|| raw.placeholder("value")),
        }
    }
}

crate::impl_language_syntax_map!(Lua, LUA_KINDS, {
    construct: {
        "function_declaration" => Function,
        "local_function"       => Function,
        "assignment_statement" => Assignment,
        "local_declaration"    => Assignment,
        "if_statement"         => Conditional,
        "function_call"        => Call,
    },
    container: {
        "chunk"      => FileRoot,
        "parameters" => ParameterList,
        "block"      => Body,
    },
});

crate::impl_lang_node_resolver!(Lua, LuaNode, LuaContainerNode);
