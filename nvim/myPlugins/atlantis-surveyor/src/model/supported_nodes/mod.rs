// ── Supported nodes ───────────────────────────────────────────────────────
//
// Each supported node follows the same pattern:
//
//   1. A state struct (e.g. `FunctionDeclaration`) holding the extracted data.
//   2. A marker trait (e.g. `HasFunctions`) that a language opts into.
//   3. A blanket `Extract` impl: `impl<Lang: HasFunctions> Extract<...> for Lang`.
//      Languages with divergent field names skip the marker and write a custom impl.
//
// Standard nodes live under `standard/` — direct language constructs with an
// identity (name, condition, value). Container nodes live under `container/` —
// structural groupings whose children are the navigable content.

pub mod container;
pub mod standard;

// Re-export everything at the top level so external paths don't need to know
// about the standard/container split.
pub use standard::{
    Assignment, HasAssignment,
    ConditionalStatement, HasConditionals,
    FunctionDeclaration, HasFunctions,
    FunctionCall, HasFunctionCalls,
    Parameter, HasParameter,
    ReturnStatement, HasReturnStatement,
};
pub use container::{
    FileRoot, HasFileRoot,
    Body, HasFunctionBody,
    ParameterList, HasParameterList,
    ExpressionList, HasExpressionList,
};
