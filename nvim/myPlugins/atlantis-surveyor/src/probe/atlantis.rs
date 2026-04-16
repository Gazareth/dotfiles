//! Future: map `TsSnapshot` into Atlantis anchor kinds / capabilities.

use super::treesitter::TsSnapshot;

pub fn classify(_snap: &TsSnapshot) -> Option<&'static str> {
    None
}
