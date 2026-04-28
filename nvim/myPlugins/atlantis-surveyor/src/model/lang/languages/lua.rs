use crate::model::kinds::{Assignment, StandardConditionals, StandardFunctions};
use crate::model::lang::NodeKind;
use crate::model::node::{Extract, RawNode};

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
    "function_declaration" => NodeKind::Function,
    "local_function"       => NodeKind::Function,
    "assignment_statement" => NodeKind::Assignment,
    "local_declaration"    => NodeKind::Assignment,
    "if_statement"         => NodeKind::Conditional,
});

crate::impl_lang_node_resolver!(Lua, LuaNode);
