//! Tree-sitter probe using Neovim's incremental tree.

mod types;
pub use types::*;

// ── Production ───────────────────────────────────────────────────────────────

#[cfg(not(test))]
mod query;
pub(crate) mod decode;

#[cfg(not(test))]
pub fn snapshot(
    row:          u32,
    col:          u32,
    target_type:  Option<&str>,
    target_start: Option<(u32, u32)>,
    target_end:   Option<(u32, u32)>,
) -> Result<NodeSnapshot, crate::error::AtlantisError> {
    let d = query::call(row, col, target_type, target_start, target_end)?;

    if d.get("err").is_some() {
        let err = decode::str(&d, "err")?;
        return Err(crate::error::AtlantisError::from_lua_err_code(&err));
    }

    decode::snapshot(&d)
}
