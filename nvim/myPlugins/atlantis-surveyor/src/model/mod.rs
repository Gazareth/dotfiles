// ── Atlantis model ────────────────────────────────────────────────────────
//
// Module layout:
//
//   node/      — RawNode, Node<Lang, State>, pipeline states, AtlantisCursor,
//                Extract trait.
//
//   kinds/     — One file per node kind. Each file owns the state struct,
//                the Standard* marker trait, and the blanket Extract impl.
//                Add a new file here for each new kind.
//
//   lang/      — Language markers, NodeKind enum, LanguageConfig trait,
//                per-language Extract overrides, node enums, resolvers.

pub mod kinds;
pub mod lang;
pub mod node;

// Re-export the most commonly used types so consumers can write:
//   use atlantis_surveyor::model::{Node, AtlantisCursor, LuaNode};
// rather than reaching into submodules.

pub use kinds::{Assignment, ConditionalStatement, FunctionDeclaration};
pub use lang::{JavaScriptNode, LuaNode, PythonNode, TypeScriptNode};
pub use node::{AtlantisCursor, Node, RawNode, Unknown, Unresolved};
pub use crate::anchor::AnchorRange as Range;
