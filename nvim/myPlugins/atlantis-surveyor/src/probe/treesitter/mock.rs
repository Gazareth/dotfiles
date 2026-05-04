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

// ── Thread-local snapshot override ───────────────────────────────────────

use std::cell::RefCell;
use crate::error::AtlantisError;

thread_local! {
    static OVERRIDE: RefCell<Option<NodeSnapshot>> = RefCell::new(None);
}

/// Pre-load a `NodeSnapshot` to be returned by the next call to `snapshot()`.
pub fn set_snapshot(snap: NodeSnapshot) {
    OVERRIDE.with(|s| *s.borrow_mut() = Some(snap));
}

/// Clear any pre-loaded snapshot override.
pub fn clear_snapshot() {
    OVERRIDE.with(|s| *s.borrow_mut() = None);
}

/// Returns the pre-loaded snapshot, or `Err(NoNode)` if none has been set.
pub fn snapshot(
    _row:          u32,
    _col:          u32,
    _target_type:  Option<&str>,
    _target_start: Option<(u32, u32)>,
) -> Result<NodeSnapshot, AtlantisError> {
    OVERRIDE.with(|s| s.borrow().clone())
        .ok_or(AtlantisError::NoNode)
}
