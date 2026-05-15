// ── Atlantis model ────────────────────────────────────────────────────────
//
// Module layout:
//
//   node/             — RawNode, NodeRange, Node<Lang, State>, pipeline states,
//                       Extract trait.
//
//   supported_nodes/  — One file per supported node. Each file owns the state
//                       struct, the marker trait, and the blanket Extract impl.
//                       Add a new file here for each new supported node type.
//
//   lang/             — Language markers, NodeKind, LanguageConfig trait,
//                       per-language Extract overrides, node enums, resolvers.
//
//   resolved/         — AnyNode wrappers.

pub mod supported_nodes;
pub mod lang;
pub mod node;
pub mod resolved;
pub mod atlantis_node;
pub mod navigation_target;

#[allow(unused_imports)]
pub use node::{Node, NodeRange};
#[allow(unused_imports)]
pub use resolved::AnyNode;
#[allow(unused_imports)]
pub use lang::{
    JavaScriptNode,
    LuaNode,
    PythonNode,
    TypeScriptNode,
};
pub use atlantis_node::AtlantisNode;
pub use navigation_target::{NavigationTarget, OutlineItem};
