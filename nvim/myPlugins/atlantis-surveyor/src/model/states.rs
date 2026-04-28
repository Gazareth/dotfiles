use serde::{Deserialize, Serialize};
use super::node::RawNode;

// ── Concrete node states ──────────────────────────────────────────────────
//
// Each struct is a pure data bag describing what Atlantis needs to know
// about a node at the current cursor position.
//
// The rule: extract only what is needed for display or immediate navigation.
// Anything the user might navigate *into* is kept as a RawNode — opaque
// until Atlantis is called again at that location.
//
// No language knowledge lives here. That belongs in common.rs and lang/.

// ── FunctionDeclaration ───────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FunctionDeclaration {
    /// The function's identifier — needed for display and search.
    pub name: String,
    /// Whether declared async — affects navigation context.
    pub is_async: bool,
    /// The parameter list. Opaque until the user drills in.
    pub parameters: RawNode,
    /// The function body. Opaque until the user drills in.
    pub body: RawNode,
}

// ── Assignment ────────────────────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Assignment {
    /// The name being assigned to — needed for display and search.
    pub name: String,
    /// Whether this introduces a new locally-scoped binding (e.g. Lua's `local`).
    pub is_local_binding: bool,
    /// The right-hand side. Opaque until the user drills in.
    pub value: RawNode,
}

// ── ConditionalStatement ──────────────────────────────────────────────────
//
// Covers if/elseif/else constructs across languages.
// All three regions are navigable anchors — Atlantis resolves them
// fresh when the user moves into any of them.

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ConditionalStatement {
    /// The condition expression. Opaque — resolved if navigated into.
    pub condition: RawNode,
    /// The block that runs when the condition passes.
    pub consequent: RawNode,
    /// The else / elif branch, if present.
    pub alternate: Option<RawNode>,
}

// ── State capabilities ────────────────────────────────────────────────────

/// The state represents something with an identifier (function, assignment, parameter).
pub trait Named {
    fn name(&self) -> &str;
}

// ── Capability implementations ────────────────────────────────────────────

impl Named for FunctionDeclaration {
    fn name(&self) -> &str {
        &self.name
    }
}

impl Named for Assignment {
    fn name(&self) -> &str {
        &self.name
    }
}
