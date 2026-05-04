// ── Language Layer ────────────────────────────────────────────────────────
//
// ── How to add a new language ─────────────────────────────────────────────
//
// 1. Create `src/model/lang/languages/your_lang.rs`.
// 2. Define a marker struct: `pub struct YourLang;`.
// 3. Opt into CLike or individual Standard*/Container* traits from `model/supported_nodes/`.
// 4. Use `impl_language_syntax_map!` to map TS kind strings to NodeKind values.
// 5. Use `impl_lang_node_resolver!` to generate the Standard + Container node enums.
// 6. Register the new module in `languages/mod.rs` and re-export below.

pub mod common;
pub mod languages;
pub mod macros;
pub mod node_kind;
pub mod resolve;

pub use common::{CLike, Common};
pub use node_kind::{LanguageConfig, NodeKind, ContainerNode, ConstructNode};
pub use languages::{
    JavaScript, JavaScriptContainerNode, JavaScriptNode,
    Lua, LuaContainerNode, LuaNode,
    Python, PythonContainerNode, PythonNode,
    TypeScript, TypeScriptContainerNode, TypeScriptNode,
};
pub use resolve::{Resolve, ResolveOutput};
