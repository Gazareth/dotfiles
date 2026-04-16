use crate::anchor::AnchorInfo;
use crate::probe::atlantis;
use crate::probe::treesitter;

pub fn build_anchor_info(bufnr: i32, row: u32, col: u32) -> AnchorInfo {
    match treesitter::capture(bufnr, row, col) {
        Ok(snap) => {
            let _kind = atlantis::classify(&snap);
            AnchorInfo::ok(
                bufnr,
                snap.node_type,
                snap.range,
                snap.text,
            )
        }
        Err(e) => AnchorInfo::err(bufnr, e),
    }
}
