use crate::model::supported_nodes::{Assignment, FunctionCall, HasBody, HasConditionals, HasFileRoot, HasFunctions, HasParameter, HasParameterList};
use crate::model::lang::{NodeClass, StructureKind, SyntaxKind};
use crate::model::node::{Extract, RawNode};

#[derive(Debug, Clone, Copy)]
pub struct Lua;

impl HasFileRoot for Lua {}
impl HasFunctions for Lua {}
impl HasConditionals for Lua {}
impl HasBody for Lua {}
impl HasParameter for Lua {}
impl HasParameterList for Lua {}

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
    "chunk"                => NodeClass::Container(StructureKind::FileRoot),
    "function_declaration" => NodeClass::Standard(SyntaxKind::Function),
    "local_function"       => NodeClass::Standard(SyntaxKind::Function),
    "assignment_statement" => NodeClass::Standard(SyntaxKind::Assignment),
    "local_declaration"    => NodeClass::Standard(SyntaxKind::Assignment),
    "if_statement"         => NodeClass::Standard(SyntaxKind::Conditional),
    "function_call"        => NodeClass::Standard(SyntaxKind::Call),
    "parameters"           => NodeClass::Container(StructureKind::ParameterList),
    "block"                => NodeClass::Container(StructureKind::Body),
});

crate::impl_lang_node_resolver!(Lua, LuaNode, LuaContainerNode);
