pub mod node;
pub(super) mod resolved;

use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
use crate::model::node::RawNode;
use crate::probe::language::{detect, Language};
use crate::probe::treesitter::{self, NodeOutline};

use self::node::AtlantisNode;
use self::resolved::ResolvedNode;
use super::NavigationTarget;

/// Language-aware view of the ancestry chain — drives navigation queries and node classification.
pub(super) struct NodeAncestry {
    raw:      Vec<NodeOutline>,
    language: Language,
}

impl NodeAncestry {
    /// Construct with no nodes — used by `SurveyResult::at_position` for language dispatch only.
    pub(super) fn for_language(filetype: &str) -> Self {
        Self { raw: vec![], language: detect(filetype) }
    }

    /// Decode a raw Lua ancestry dict, resolve the focus and optional ancestor, return both.
    pub(super) fn decode(bufnr: i32, raw: &Dictionary) -> Result<Vec<ResolvedNode>, AtlantisError> {
        let (filetype, outlines) = treesitter::decode::ancestry::decode(raw)?;
        let ancestry = Self { raw: outlines, language: detect(&filetype) };

        let supported = ancestry.supported_indices();
        if supported.is_empty() {
            return Err(AtlantisError::Api("no supported node in ancestry".into()));
        }

        let top_level = ancestry.top_level();

        let mut out = vec![
            ResolvedNode::resolve(bufnr, supported[0], &ancestry, top_level.clone())?
        ];

        if let Some(&ancestor_idx) = supported.get(1) {
            if let Ok(cn) = ResolvedNode::resolve(bufnr, ancestor_idx, &ancestry, top_level) {
                (&mut out).push(cn);
            }
        }

        Ok(out)
    }

    pub(super) fn resolve_node(&self, raw: RawNode) -> AtlantisNode {
        AtlantisNode::from_raw(raw, &self.language)
    }

    pub(super) fn top_level(&self) -> Option<NavigationTarget> {
        self.raw.iter().rev()
            .find(|n| !matches!(self.resolve_node(RawNode::from(*n)), AtlantisNode::Unrecognised))
            .map(NavigationTarget::from)
    }

    pub(super) fn parent_of(&self, idx: usize) -> Option<NavigationTarget> {
        self.raw.iter().skip(idx + 1)
            .find(|n| !matches!(self.resolve_node(RawNode::from(*n)), AtlantisNode::Unrecognised))
            .map(NavigationTarget::from)
    }

    pub(super) fn supported_indices(&self) -> Vec<usize> {
        self.raw.iter().enumerate()
            .filter(|(_, n)| !matches!(self.resolve_node(RawNode::from(*n)), AtlantisNode::Unrecognised))
            .map(|(i, _)| i)
            .collect()
    }

    pub(super) fn get(&self, idx: usize) -> &NodeOutline {
        &self.raw[idx]
    }
}
