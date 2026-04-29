// ── Atlantis model ────────────────────────────────────────────────────────
//
// Module layout:
//
//   node/             — RawNode, NodeRange, Node<Lang, State>, pipeline states,
//                       AtlantisCursor, Extract + HasSiblings traits.
//
//   supported_nodes/  — One file per supported node. Each file owns the state
//                       struct, the Standard*/Container* marker trait, and the
//                       blanket Extract impl. Add a new file here for each new
//                       supported node type.
//
//   lang/             — Language markers, NodeClass/ConstructNode/ContainerNode,
//                       LanguageConfig trait, per-language Extract overrides,
//                       node enums, resolvers.
//
//   resolved/         — AnyConstructNode + AnyContainerNode wrappers.

pub mod supported_nodes;
pub mod lang;
pub mod node;
pub mod resolved;

pub use supported_nodes::{Assignment, ConditionalStatement, FunctionDeclaration};
pub use lang::{
    JavaScriptContainerNode, JavaScriptNode,
    LuaContainerNode, LuaNode,
    PythonContainerNode, PythonNode,
    TypeScriptContainerNode, TypeScriptNode,
};
pub use node::{AtlantisCursor, Node, NodeRange, RawNode, Unknown, Unresolved};
pub use resolved::{AnyContainerNode, AnyConstructNode};
