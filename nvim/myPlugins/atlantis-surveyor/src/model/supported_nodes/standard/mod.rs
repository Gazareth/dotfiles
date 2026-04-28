pub mod assignment;
pub mod conditional;
pub mod function;

pub use assignment::{Assignment, HasAssignment};
pub use conditional::{ConditionalStatement, HasConditionals};
pub use function::{FunctionDeclaration, HasFunctions, FunctionCall, HasFunctionCalls, Parameter, HasParameter};

/// State capability: the node represents something with a displayable identifier.
pub trait Named {
    fn name(&self) -> &str;
}
