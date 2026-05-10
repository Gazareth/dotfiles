//! Test-build replacement for the `treesitter` module.
//!
//! Re-uses all type definitions and `From` impls from `types.rs` (identical to
//! production) and only replaces `snapshot()` with a thread-local mock.
//! The `decode` stub satisfies the `ancestry.rs` import; it panics if
//! accidentally reached since `NodeAncestry::parse` is never called in tests.
//!
//! This file is only compiled when `#[cfg(test)]` is active, via the `#[path]`
//! declaration in `probe/mod.rs`. Production builds use `mod.rs` exclusively.

// ── Shared types (defined once in types.rs, used by both mod.rs and mock.rs)

mod types;
pub use types::*;

// ── Decode stub ───────────────────────────────────────────────────────────
//
// `ancestry.rs` imports `treesitter::decode::ancestry::decode`. That code path
// can only be reached via the live `nvim_oxi` entry point — never from tests.

pub mod decode {
    pub mod ancestry {
        use nvim_oxi::Dictionary;
        use crate::error::AtlantisError;
        use super::super::NodeOutline;

        pub fn decode(_d: &Dictionary) -> Result<(String, Vec<NodeOutline>), AtlantisError> {
            panic!("treesitter::decode::ancestry::decode must not be called in test builds")
        }
    }

    use nvim_oxi::Dictionary;
    use crate::error::AtlantisError;
    pub fn str(_d: &Dictionary, _key: &str) -> Result<String, AtlantisError> { unreachable!() }
}

// ── Thread-local snapshot queue ─────────────────────────────────────────

use std::cell::RefCell;
use std::collections::VecDeque;
use crate::error::AtlantisError;

thread_local! {
    static QUEUE: RefCell<VecDeque<NodeSnapshot>> = RefCell::new(VecDeque::new());
}

/// Replace the snapshot queue with a single snapshot (backward-compatible with existing tests).
pub fn set_snapshot(snap: NodeSnapshot) {
    QUEUE.with(|q| {
        let mut q = q.borrow_mut();
        q.clear();
        q.push_back(snap);
    });
}

/// Append a snapshot to the queue. Calls to `snapshot()` consume from the front.
pub fn push_snapshot(snap: NodeSnapshot) {
    QUEUE.with(|q| q.borrow_mut().push_back(snap));
}

/// Clear all queued snapshots.
pub fn clear_snapshot() {
    QUEUE.with(|q| q.borrow_mut().clear());
}

/// Pop and return the next queued snapshot, or `Err(NoNode)` if the queue is empty.
pub fn snapshot(
    _row:          u32,
    _col:          u32,
    _target_type:  Option<&str>,
    _target_start: Option<(u32, u32)>,
    _target_end:   Option<(u32, u32)>,
) -> Result<NodeSnapshot, AtlantisError> {
    QUEUE.with(|q| q.borrow_mut().pop_front())
        .ok_or(AtlantisError::NoNode)
}
