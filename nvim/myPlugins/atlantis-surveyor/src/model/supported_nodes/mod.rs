pub mod assignment;
pub mod conditional;
pub mod function;

pub use assignment::{Assignment, HasAssignment};
pub use conditional::{ConditionalStatement, HasConditionals};
pub use function::{FunctionDeclaration, HasFunctions, Body, HasBody, ParameterList, HasParameterList};

/// State capability: the node represents something with an identifier.
pub trait Named {
    fn name(&self) -> &str;
}
