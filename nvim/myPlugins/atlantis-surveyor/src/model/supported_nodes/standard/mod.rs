pub mod assignment;
pub mod conditional;
pub mod function;
pub mod loop_statement;
pub mod return_statement;

pub use assignment::{Assignment, HasAssignment};
pub use conditional::{ConditionalStatement, HasConditionals};
pub use function::{FunctionDeclaration, HasStandardFunctions, FunctionCall, HasFunctionCalls, Parameter, HasParameter};
pub use loop_statement::{LoopStatement, HasLoops};
pub use return_statement::{ReturnStatement, HasReturnStatement};

/// State capability: the node represents something with a displayable identifier.
pub trait Named {
    fn name(&self) -> &str;
}
