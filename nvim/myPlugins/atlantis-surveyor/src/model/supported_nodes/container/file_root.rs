use crate::model::node::{Extract, RawNode};

/// The top-level scope of a file — contains all statements at the root level.
/// Atlantis always provides a jump to this node regardless of cursor position.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct FileRoot {
    pub statements: Vec<RawNode>,
}

pub trait HasFileRoot {}

impl<Lang: HasFileRoot> Extract<FileRoot> for Lang {
    fn extract(raw: &RawNode) -> FileRoot {
        FileRoot {
            statements: raw.children.clone(),
        }
    }
}
