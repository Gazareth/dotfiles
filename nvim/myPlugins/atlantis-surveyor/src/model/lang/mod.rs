// ── Language Layer ────────────────────────────────────────────────────────
//
// ── How to add a new language ─────────────────────────────────────────────
//
// 1. Create `src/model/lang/languages/your_lang.rs`.
// 2. Define a marker struct: `pub struct YourLang;`.
// 3. Opt into syntax groups in `common.rs` (e.g., `impl CLike for YourLang {}`).
// 4. Use `impl_language_syntax_map!` to map TS kind strings to categories.
// 5. Use `impl_lang_node_resolver!` to generate the collecting enum and resolver.
// 6. Register the new module in `languages/mod.rs` and re-export below.

pub mod category;
pub mod languages;
pub mod macros;
pub mod resolve;

pub use category::{LanguageConfig, NodeCategory};
pub use languages::{JavaScript, JavaScriptNode, Lua, LuaNode, Python, PythonNode, TypeScript, TypeScriptNode};
pub use resolve::Resolve;
