use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
use crate::model::node::RawNode;
use crate::model::AtlantisNode;
use crate::probe::language::{detect, Language};
use crate::probe::treesitter::{self, NodeOutline};

/// Language-aware view of the ancestry chain.
/// The `root` field guarantees at least one node is always present.
pub(super) struct NodeAncestry {
    inner:    Vec<NodeOutline>,  // innermost nodes, cursor → just inside the file root
    root:     NodeOutline,       // always the outermost — validated as a file root on construction
    language: Language,
}

impl NodeAncestry {
    /// Parse a raw Lua ancestry dict.
    ///
    /// Fails if the ancestry is empty or, for known languages, if the outermost
    /// node is not a recognised file root (indicating malformed input).
    /// Unknown languages pass through — `FocusedNode::from_ancestry` will return `None` for them.
    pub(super) fn parse(raw: &Dictionary) -> Result<Self, AtlantisError> {
        let (filetype, mut outlines) = treesitter::decode::ancestry::decode(raw)?;
        let language = detect(&filetype);

        let root = outlines.pop()
            .ok_or_else(|| AtlantisError::Api("empty ancestry".into()))?;

        if let Some(false) = language.is_file_root(&root.node_type) {
            return Err(AtlantisError::Api(
                format!("ancestry root '{}' is not a file root node", root.node_type)
            ));
        }

        Ok(Self { inner: outlines, root, language })
    }

    pub(super) fn all(&self) -> impl Iterator<Item = &NodeOutline> {
        self.inner.iter().chain(std::iter::once(&self.root))
    }

    pub(super) fn classify(&self, raw: RawNode) -> AtlantisNode {
        AtlantisNode::from_raw(raw, &self.language)
    }
}
