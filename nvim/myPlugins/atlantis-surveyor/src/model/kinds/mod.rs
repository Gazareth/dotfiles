pub mod assignment;
pub mod conditional;
pub mod function;

pub use assignment::{Assignment, StandardAssignment};
pub use conditional::{ConditionalStatement, StandardConditionals};
pub use function::{FunctionDeclaration, StandardFunctions};

/// State capability: the node represents something with an identifier.
pub trait Named {
    fn name(&self) -> &str;
}
