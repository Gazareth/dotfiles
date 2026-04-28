use crate::model::supported_nodes::{HasAssignment, HasBody, HasConditionals, HasFunctions, HasFunctionCalls, HasParameter, HasParameterList};

// ── Convenience bundle ────────────────────────────────────────────────────
//
// CLike bundles all standard and container marker traits for C-family
// languages. Implementing CLike satisfies each individual marker trait
// automatically via the blanket impls below.

pub trait CLike:
    HasFunctions + HasFunctionCalls + HasAssignment + HasConditionals
    + HasBody + HasParameter + HasParameterList
{}

impl<Lang: CLike> HasFunctions for Lang {}
impl<Lang: CLike> HasFunctionCalls for Lang {}
impl<Lang: CLike> HasAssignment for Lang {}
impl<Lang: CLike> HasConditionals for Lang {}
impl<Lang: CLike> HasBody for Lang {}
impl<Lang: CLike> HasParameter for Lang {}
impl<Lang: CLike> HasParameterList for Lang {}
