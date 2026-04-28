// ── Atlantis model ────────────────────────────────────────────────────────
//
// Module layout:
//
//   node.rs    — RawNode, Node<Lang, State>, pipeline states, capability
//                traits (Named), Extract trait, AtlantisCursor
//
//   states.rs  — Concrete node states: FunctionDeclaration, Assignment,
//                ConditionalStatement. Pure data, no language knowledge.
//
//   common.rs  — Syntax grouping marker traits (StandardFunctions etc.),
//                CLike bundle, and blanket Extract impls for shared syntax.
//
//   lang.rs    — Language markers (Lua, Python, TypeScript, JavaScript),
//                LanguageConfig (TS kind string → NodeCategory mapping),
//                per-language Extract overrides, collecting enums,
//                and per-language resolve() entry points.

pub mod common;
pub mod lang;
pub mod node;
pub mod states;

// Re-export the most commonly used types so consumers can write:
//   use atlantis_surveyor::model::{Node, AtlantisCursor, LuaNode};
// rather than reaching into submodules.

pub use lang::{JavaScriptNode, LuaNode, PythonNode, TypeScriptNode};
pub use node::{AtlantisCursor, Node, RawNode, Unknown, Unresolved};
pub use states::{Assignment, ConditionalStatement, FunctionDeclaration};
pub use crate::anchor::AnchorRange as Range;
