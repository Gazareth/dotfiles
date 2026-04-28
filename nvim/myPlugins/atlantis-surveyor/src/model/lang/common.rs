use crate::model::kinds::{StandardAssignment, StandardConditionals, StandardFunctions};

// ── Convenience bundle ────────────────────────────────────────────────────
//
// CLike bundles all three standard groups for languages that share
// most C-family surface syntax. Implementing CLike satisfies all three
// individual marker traits automatically via the blanket impls below.

pub trait CLike: StandardFunctions + StandardAssignment + StandardConditionals {}

impl<Lang: CLike> StandardFunctions for Lang {}
impl<Lang: CLike> StandardAssignment for Lang {}
impl<Lang: CLike> StandardConditionals for Lang {}
