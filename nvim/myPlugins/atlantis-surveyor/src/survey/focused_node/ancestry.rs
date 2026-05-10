use nvim_oxi::Dictionary;

use crate::error::AtlantisError;
use crate::model::{AtlantisNode, FocusMode};
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
        focus_mode: FocusMode,
        target_hint: Option<(&str, u32, u32)>,
    ) -> Result<usize, AtlantisError> {
        let lang = self.language;
        let all: Vec<&NodeOutline> = self.all().collect();

        let candidate_idx = if let Some((target_type, target_row, target_col)) = target_hint {
            // For Container targets, pick the outermost match: nested containers of the same type
            // (e.g. binary_expression inside binary_expression) share the same start position,
            // and the hint was generated from the outer one. The outward walk is also skipped
            // for hinted containers — the hint is already authoritative.
            if focus_mode == FocusMode::Container {
                let idx = all.iter().enumerate()
                    .filter(|(_, n)| n.node_type == target_type && n.range.start_row == target_row && n.range.start_col == target_col)
                    .last()
                    .map(|(i, _)| i)
                    .ok_or(AtlantisError::UnsupportedLanguage)?;
                return Ok(idx);
            }
            all.iter().position(|n| {
                n.node_type == target_type
                && n.range.start_row == target_row
                && n.range.start_col == target_col
            }).ok_or(AtlantisError::UnsupportedLanguage)?
        } else {
            // Find the innermost node that matches our focus mode's criteria.
            all.iter().enumerate().position(|(i, n)| {
                let parent = all.get(i + 1);
                let classified = lang.classify(RawNode::from(*n), parent.copied());
                
                match (focus_mode, classified) {
                    // In Container mode, we ONLY stop at containers.
                    (FocusMode::Container, AtlantisNode::Container(_)) => true,
                    
                    // In Construct mode (standard), we stop at Constructs or Leaf tokens.
                    (FocusMode::Construct, AtlantisNode::Construct(_)) => true,
                    (FocusMode::Construct, AtlantisNode::Leaf)         => true,
                    
                    // Fallback for index 0 (Unrecognised literals/operands).
                    // We only apply this in Construct mode; in Container mode, we always
                    // want to climb to the structural parent.
                    _ if i == 0 && focus_mode == FocusMode::Construct => {
                        parent.map_or(true, |p| {
                            // Only climb if the parent is a Construct and we start at the same position.
                            // This allows staying at an operand that starts a Container (like nil in local x = nil).
                            let parent_node = lang.classify(RawNode::from(*p), None);
                            let is_parent_construct = matches!(parent_node, AtlantisNode::Construct(_));
                            let starts_later = n.range.start_row > p.range.start_row 
                                            || (n.range.start_row == p.range.start_row && n.range.start_col > p.range.start_col);
                            
                            !is_parent_construct || starts_later
                        })
                    }
                    _ => false,
                }
            }).ok_or(AtlantisError::UnsupportedLanguage)?
        };

        // Walk upward through consecutive ancestors of the same construct kind
        // (e.g. `assignment_statement` → `variable_declaration` both resolve to Assignment).
        // Leaf nodes are never walked upward — they stay at exactly the candidate position.
        let candidate_kind = lang.classify(RawNode::from(all[candidate_idx]), all.get(candidate_idx + 1).copied());
        if matches!(candidate_kind, AtlantisNode::Leaf | AtlantisNode::Unrecognised) {
            return Ok(candidate_idx); // Leaf/Unrecognised candidate — no upward walk
        }
        Ok(all[candidate_idx..].iter()
            .enumerate()
            .take_while(|(i, n)| candidate_kind.same_construct_kind(
                &lang.classify(RawNode::from(**n), all.get(candidate_idx + i + 1).copied())
            ))
            .last()
            .map(|(i, _)| candidate_idx + i)
            .unwrap_or(candidate_idx))
    }
}
