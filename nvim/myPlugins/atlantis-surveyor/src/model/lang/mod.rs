// ── Language Layer ────────────────────────────────────────────────────────
//
// ── How to add a new language ─────────────────────────────────────────────
//
// 1. Create `src/model/lang/languages/your_lang.rs`.
// 2. Define a marker struct: `pub struct YourLang;`.
// 3. Opt into CLike or individual Standard* traits from `model/kinds/`.
// 4. Use `impl_language_syntax_map!` to map TS kind strings to NodeKind values.
// 5. Use `impl_lang_node_resolver!` to generate the node enum and resolver.
// 6. Register the new module in `languages/mod.rs` and re-export below.

pub mod common;
pub mod languages;
pub mod macros;
pub mod node_kind;
pub mod resolve;

pub use common::CLike;
pub use node_kind::{LanguageConfig, NodeKind};
pub use languages::{JavaScript, JavaScriptNode, Lua, LuaNode, Python, PythonNode, TypeScript, TypeScriptNode};
pub use resolve::Resolve;
