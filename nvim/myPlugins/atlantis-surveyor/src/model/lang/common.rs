use crate::model::supported_nodes::{HasAssignment, HasFunctionBody, HasConditionals, HasFileRoot, HasFunctions, HasFunctionCalls, HasParameter, HasParameterList, HasReturnStatement};

// ── Convenience bundles ───────────────────────────────────────────────────
//
// Common bundles traits universal across all supported languages — excluding
// HasFunctionCalls (field names vary, e.g. Lua) and HasAssignment (same).
//
// CLike extends Common with HasFunctionCalls + HasAssignment for languages
// where both follow standard C-family field names (JavaScript, TypeScript).

pub trait Common:
    HasFileRoot
    + HasFunctions + HasConditionals
    + HasFunctionBody + HasParameter + HasParameterList
    + HasReturnStatement
{}

impl<Lang: Common> HasConditionals for Lang {}
impl<Lang: Common> HasFileRoot for Lang {}
impl<Lang: Common> HasFunctions for Lang {}
impl<Lang: Common> HasFunctionBody for Lang {}
impl<Lang: Common> HasParameter for Lang {}
impl<Lang: Common> HasParameterList for Lang {}
impl<Lang: Common> HasReturnStatement for Lang {}

pub trait CLike: Common + HasFunctionCalls + HasAssignment {}

impl<Lang: CLike> Common for Lang {}
impl<Lang: CLike> HasFunctionCalls for Lang {}
impl<Lang: CLike> HasAssignment for Lang {}
