use std::marker::PhantomData;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};
use crate::anchor::AnchorRange;

pub mod traits;
pub use traits::Extract;

// ── Raw data from Tree-sitter (populated via Lua API) ─────────────────────
//
// RawNode is an opaque handle into the Tree-sitter tree. It carries just
// enough to identify and locate a node. Resolution into a typed state is
// always lazy — only triggered when Atlantis navigates to that position.

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RawNode {
    pub kind: String,
    pub text: String,
    pub range: AnchorRange,
    /// Named children probed from the Lua API, keyed by Tree-sitter field name.
    /// e.g. "name" -> identifier node, "body" -> block node, "condition" -> expr node
    pub fields: HashMap<String, RawNode>,
}

impl RawNode {
    /// Text of a named child field (e.g. "name").
    pub fn field_text(&self, field: &str) -> String {
        self.fields
            .get(field)
            .map(|n| n.text.clone())
            .unwrap_or_default()
    }

    /// Whether a named field exists (used to detect modifiers like "async", "local").
    pub fn has_field(&self, field: &str) -> bool {
        self.fields.contains_key(field)
    }

    /// Return a child field as its own RawNode, if present.
    pub fn field(&self, field: &str) -> Option<&RawNode> {
        self.fields.get(field)
    }

    /// Empty stand-in for a missing field, inheriting this node's range.
    pub(crate) fn placeholder(&self, kind: &str) -> RawNode {
        RawNode {
            kind: kind.to_string(),
            text: String::new(),
            range: self.range.clone(),
            fields: std::collections::HashMap::new(),
        }
    }
}

// ── Pipeline states ───────────────────────────────────────────────────────

/// Received from Tree-sitter. Resolution has not been attempted.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Unknown;

/// Resolution was attempted. The node kind matched nothing registered for this language.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Unresolved;

// ── The Node type ─────────────────────────────────────────────────────────
//
// Node<Lang, State> carries raw Tree-sitter data plus a typed state.
// State defaults to Unknown — a Node<Lua> is an unprocessed Lua node.
// Advancing the cursor resolves Unknown into a concrete state.

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Node<Lang, State = Unknown> {
    pub raw: RawNode,
    pub state: State,
    #[serde(skip)]
    pub _lang: PhantomData<Lang>,
}

impl<Lang, State> Node<Lang, State> {
    pub fn range(&self) -> &AnchorRange {
        &self.raw.range
    }

    pub fn kind(&self) -> &str {
        &self.raw.kind
    }
}

impl<Lang> Node<Lang, Unknown> {
    pub fn new(raw: RawNode) -> Self {
        Self {
            raw,
            state: Unknown,
            _lang: PhantomData,
        }
    }
}

// ── Cursor ────────────────────────────────────────────────────────────────
//
// AtlantisCursor is the result of navigating to any position in the tree.
// It holds the resolved current node plus opaque handles for everything
// immediately surrounding it. Parent, siblings, and children are RawNodes
// — they remain unresolved until the user navigates to them, at which
// point a new cursor is produced for that position.

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AtlantisCursor<Lang, State> {
    /// The node at the current position, fully resolved.
    pub current: Node<Lang, State>,
    /// Where we came from. None if we are at the root.
    pub parent: Option<RawNode>,
    /// Peers at this level in the tree, unresolved.
    pub siblings: Vec<RawNode>,
    /// Immediate children of the current node, unresolved.
    pub children: Vec<RawNode>,
}
