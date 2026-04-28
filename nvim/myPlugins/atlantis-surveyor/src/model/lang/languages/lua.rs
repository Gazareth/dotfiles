use crate::model::common::*;
use crate::model::lang::NodeCategory;
use crate::model::node::{Extract, RawNode};
use crate::model::states::Assignment;

#[derive(Debug, Clone, Copy)]
pub struct Lua;

impl StandardFunctions for Lua {}
impl StandardConditionals for Lua {}

impl Extract<Assignment> for Lua {
    fn extract(raw: &RawNode) -> Assignment {
        Assignment {
            name: raw.field_text("name"),
            is_local_binding: raw.kind == "local_declaration",
            value: raw.field("value").cloned().unwrap_or_else(|| raw.placeholder("value")),
        }
    }
}

crate::impl_language_syntax_map!(Lua, LUA_KINDS, {
    "function_declaration" => NodeCategory::Function,
    "local_function"       => NodeCategory::Function,
    "assignment_statement" => NodeCategory::Assignment,
    "local_declaration"    => NodeCategory::Assignment,
    "if_statement"         => NodeCategory::Conditional,
});

crate::impl_lang_node_resolver!(Lua, LuaNode);
