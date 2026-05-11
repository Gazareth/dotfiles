// ── Supported nodes ───────────────────────────────────────────────────────
//
// Each supported node follows the same pattern:
//
//   1. A state struct (e.g. `FunctionDeclaration`) holding the extracted data.
//   2. A marker trait (e.g. `HasFunctions`) that a language opts into.
//   3. A blanket `Extract` impl: `impl<Lang: HasFunctions> Extract<...> for Lang`.
//      Languages with divergent field names skip the marker and write a custom impl.
//
// Structural grouping nodes (Body, ParameterList, ExpressionList, FileRoot) live
// under `container/` and are transparent during ancestry traversal.
// Semantic constructs (Function, Assignment, etc.) live under `standard/`.

pub mod container;
pub mod standard;

// Re-export everything at the top level so external paths don't need to know
// about the standard/container split.
pub use standard::{
    Assignment, HasAssignment,
    ConditionalStatement, HasConditionals,
    FunctionDeclaration, HasStandardFunctions,
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
