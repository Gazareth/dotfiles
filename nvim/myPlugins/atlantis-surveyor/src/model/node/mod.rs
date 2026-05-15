use std::marker::PhantomData;
use std::collections::HashMap;
use serde::{Deserialize, Serialize};

pub mod traits;
pub use traits::Extract;

// ── Positional range ──────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct NodeRange {
    pub start_row: u32,
    pub start_col: u32,
    pub end_row: u32,
    pub end_col: u32,
}



// ── Raw data from Tree-sitter (populated via Lua API) ─────────────────────
//
// RawNode is an opaque handle into the Tree-sitter tree. It carries just
// enough to identify and locate a node. Resolution into a typed state is
// always lazy — only triggered when Atlantis navigates to that position.

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RawNode {
    pub kind: String,
    pub text: String,
    pub range: NodeRange,
    /// Named children keyed by Tree-sitter field name (e.g. "name", "body").
    pub fields: HashMap<String, RawNode>,
    /// All named children in source order (e.g. parameters, statements).
    pub children: Vec<RawNode>,
    /// Named child count from Tree-sitter (populated from NodeOutline; 0 for snapshot-derived nodes).
    #[serde(default)]
    pub child_count: usize,
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
            fields: HashMap::new(),
            children: vec![],
            child_count: 0,
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

impl<Lang> Node<Lang, Unknown> {
    pub fn new(raw: RawNode) -> Self {
        Self {
            raw,
            state: Unknown,
            _lang: PhantomData,
        }
    }
}

