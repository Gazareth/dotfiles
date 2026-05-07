use crate::model::supported_nodes::{Assignment, FunctionCall};
use crate::model::NavigationTarget;
use crate::model::lang::Common;
use crate::model::node::{Extract, RawNode};

#[derive(Debug, Clone, Copy)]
pub struct Lua;

impl Common for Lua {}

impl Extract<FunctionCall> for Lua {
    fn extract(raw: &RawNode) -> FunctionCall {
        FunctionCall {
            // Lua function_call uses `name`, not `function`, for the callee field.
            name:       raw.field_text("name"),
            parameters: raw.field("args").map(NavigationTarget::container),
        }
    }
}

impl Extract<Assignment> for Lua {
    fn extract(raw: &RawNode) -> Assignment {
        match raw.kind.as_str() {
            // Modern nvim-treesitter grammar: `local x = y` →
            // variable_declaration( local, assignment_statement( variable_list, =, expression_list ) )
            // No field names — children are positional: variable_list then expression_list.
            "variable_declaration" => {
                let inner = raw.children.first();
                let name = inner
                    .map(|c| c.text.split('=').next().unwrap_or("").trim().to_string())
                    .unwrap_or_default();
                let lhs   = inner.and_then(|c| c.children.first()).map(NavigationTarget::construct);
                let value = inner.and_then(|c| c.children.get(1)).map(NavigationTarget::construct);
                Assignment { name, is_local_binding: true, lhs, value }
            }
            // Modern grammar: bare `x = y` → assignment_statement( variable_list, =, expression_list )
            "assignment_statement" => Assignment {
                name:             raw.children.first().map(|c| c.text.clone()).unwrap_or_default(),
                is_local_binding: false,
                lhs:              raw.children.first().map(NavigationTarget::construct),
                value:            raw.children.get(1).map(NavigationTarget::construct),
            },
            // Old nvim-treesitter grammar (field names: "name", "value")
            _ => Assignment {
                name:             raw.field_text("name"),
                is_local_binding: raw.kind == "local_declaration",
                lhs:              raw.field("name").map(NavigationTarget::construct),
                value:            raw.field("value").map(NavigationTarget::construct),
            },
        }
    }
}

crate::impl_language_syntax_map!(Lua, LUA_KINDS, {
    construct: {
        "function_declaration" => Function,
        "local_function"       => Function,
        "assignment_statement"    => Assignment,
        "local_declaration"      => Assignment,
        "variable_declaration"   => Assignment,
        "if_statement"         => Conditional,
        "function_call"        => Call,
        "parameter"            => Parameter,
        "return_statement"     => ReturnStatement,
    },
    container: {
        "chunk"      => FileRoot,
        "parameters" => ParameterList,
        "block"      => Body,
    },
});

crate::impl_lang_node_resolver!(Lua, LuaNode, LuaContainerNode);
