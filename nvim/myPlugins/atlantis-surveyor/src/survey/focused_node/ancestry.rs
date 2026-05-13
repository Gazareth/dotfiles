use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
use crate::model::AtlantisNode;
use crate::model::node::RawNode;
use crate::probe::language::{detect, Language};
use crate::probe::treesitter::{self, NodeOutline};

/// Language-aware view of the ancestry chain.
/// The `root` field guarantees at least one node is always present.
#[derive(Clone)]
pub struct NodeAncestry {
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

    #[cfg(test)]
    pub fn new_test(inner: Vec<NodeOutline>, root: NodeOutline, language: Language) -> Self {
        Self { inner, root, language }
    }

    pub fn language(&self) -> Language {
        self.language
    }

    pub fn all(&self) -> impl Iterator<Item = &NodeOutline> {
        self.inner.iter().chain(std::iter::once(&self.root))
    }

    /// Returns the index into `all()` of the node that should be focused.
    /// Applies the target-hint pin (or innermost-match fallback), then walks
    /// upward through consecutive ancestors of the same construct kind.
    pub(super) fn find_focus_idx(
        &self,
        target_hint: Option<(&str, u32, u32)>,
    ) -> Result<usize, AtlantisError> {
        let lang = self.language;
        let all: Vec<&NodeOutline> = self.all().collect();

        let candidate_idx = if let Some((target_type, target_row, target_col)) = target_hint {
            all.iter().position(|n| {
                n.node_type == target_type
                && n.range.start_row == target_row
                && n.range.start_col == target_col
            }).ok_or(AtlantisError::UnsupportedLanguage)?
        } else {
            // Find the innermost node that matches our criteria.
            all.iter().enumerate().position(|(i, n)| {
                let parent = all.get(i + 1);
                let classified = lang.classify(RawNode::from(*n), parent.copied());
                
                match classified {
                    AtlantisNode::Recognised(_) => true,
                    AtlantisNode::Leaf         => true,
                    
                    _ => false,
                }
            }).ok_or(AtlantisError::UnsupportedLanguage)?
        };

        // Walk upward through consecutive ancestors of the same construct kind
        // (e.g. `assignment_statement` → `variable_declaration` both resolve to Assignment).
        // Leaf nodes are never walked upward — they stay at exactly the candidate position.
        let candidate_kind = lang.classify(RawNode::from(all[candidate_idx]), all.get(candidate_idx + 1).copied());
        if matches!(candidate_kind, AtlantisNode::Leaf) {
            return Ok(candidate_idx);
        }

        // Transparent node with ≤1 child (Unrecognised via Guard B):
        // 1. Look inward — if the single child in the ancestry is itself Recognised, focus it.
        //    (e.g. expression_list wrapping a multi-element table_constructor)
        // 2. Otherwise climb outward, then fall through to the same_construct_kind walk
        //    so that e.g. assignment_statement merges up into variable_declaration.
        let walk_start = if matches!(candidate_kind, AtlantisNode::Unrecognised) {
            if candidate_idx > 0 {
                let inner_kind = lang.classify(
                    RawNode::from(all[candidate_idx - 1]),
                    all.get(candidate_idx).copied(),
                );
                if matches!(inner_kind, AtlantisNode::Recognised(_)) {
                    return Ok(candidate_idx - 1);
                }
            }
            (candidate_idx + 1..all.len())
                .find(|&i| matches!(
                    lang.classify(RawNode::from(all[i]), all.get(i + 1).copied()),
                    AtlantisNode::Recognised(_) | AtlantisNode::Leaf
                ))
                .unwrap_or(candidate_idx)
        } else {
            candidate_idx
        };

        let walk_kind = lang.classify(RawNode::from(all[walk_start]), all.get(walk_start + 1).copied());
        if matches!(walk_kind, AtlantisNode::Leaf | AtlantisNode::Unrecognised) {
            return Ok(walk_start);
        }
        Ok(all[walk_start..].iter()
            .enumerate()
            .take_while(|(i, n)| walk_kind.same_construct_kind(
                &lang.classify(RawNode::from(**n), all.get(walk_start + i + 1).copied())
            ))
            .last()
            .map(|(i, _)| walk_start + i)
            .unwrap_or(walk_start))
    }
}
