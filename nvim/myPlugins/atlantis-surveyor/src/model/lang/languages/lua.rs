use crate::model::supported_nodes::{Assignment, FunctionCall};
use crate::model::NavigationTarget;
use crate::model::lang::Common;
use crate::model::node::{Extract, NodeRange, RawNode};

#[derive(Debug, Clone, Copy)]
pub struct Lua;

impl Common for Lua {}

impl Extract<FunctionCall> for Lua {
    fn extract(raw: &RawNode) -> FunctionCall {
        FunctionCall {
            // Lua function_call uses `name`, not `function`, for the callee field.
            name:       raw.field_text("name"),
            parameters: raw.field("args").map(|r| NavigationTarget::from_raw(&r)),
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
                // inner is the child assignment_statement — its range starts at the variable
                // name (NOT at 'local'), so using it directly gives the correct lhs position.
                let inner = raw.children.first();
                let name = inner
                    .map(|c| c.text.split('=').next().unwrap_or("").trim().to_string())
                    .unwrap_or_default();
                // Use "variable_list" as the target type even though we only have the
                // parent assignment_statement's range — they share the same start position.
                // This lets the target_hint pin to variable_list rather than walking up
                // through the same-kind chain to variable_declaration again.
                let lhs = inner.map(|c| NavigationTarget {
                    node_type:      "variable_list".to_string(),
                    classification: String::new(),
                    range:          c.range.clone(),
                    key:            Some("n"),
                });
                // Grandchildren aren't available, so compute the RHS position from the text.
                let value = inner.and_then(|c| {
                    let eq_pos = c.text.find('=')?;
                    let rhs_text = c.text[eq_pos + 1..].trim_start();
                    let rhs_offset = (c.text.len() - rhs_text.len()) as u32;
                    Some(NavigationTarget {
                        node_type: "expression_list".to_string(),
                        classification: String::new(),
                        range: NodeRange {
                            start_row: c.range.start_row,
                            start_col: c.range.start_col + rhs_offset,
                            end_row:   c.range.end_row,
                            end_col:   c.range.end_col,
                        },
                        key: Some("v"),
                    })
                });
                Assignment { name, is_local_binding: true, lhs, value }
            }
            // Modern grammar: bare `x = y` → assignment_statement( variable_list, =, expression_list )
            "assignment_statement" => Assignment {
                name:             raw.children.first().map(|c| c.text.clone()).unwrap_or_default(),
                is_local_binding: false,
                lhs:              raw.children.first().map(|r| NavigationTarget::with_key(&r, "n")),
                value:            raw.children.get(1).map(|r| NavigationTarget::with_key(&r, "v")),
            },
            // Old nvim-treesitter grammar (field names: "name", "value")
            _ => Assignment {
                name:             raw.field_text("name"),
                is_local_binding: raw.kind == "local_declaration",
                lhs:              raw.field("name").map(|r| NavigationTarget::from_raw(&r)),
                value:            raw.field("value").map(|r| NavigationTarget::from_raw(&r)),
            },
        }
    }
}

crate::impl_language_syntax_map!(Lua, LUA_KINDS, {
    "function_declaration" => Function,
    "local_function"       => Function,
    "assignment_statement"    => Assignment,
    "local_declaration"      => Assignment,
    "variable_declaration"   => Assignment,
    "if_statement"         => Conditional,
    "function_call"        => Call,
    "parameter"            => Parameter,
    "return_statement"          => ReturnStatement,
    "chunk"              => FileRoot,
    "parameters"         => ParameterList,
    "block"              => Body,
    "variable_list"      => ParameterList,
    "expression_list"    => ExpressionList,
    "binary_expression"  => ExpressionList,
    "arguments"          => ExpressionList,
});

crate::impl_lang_node_resolver!(Lua, LuaNode);
