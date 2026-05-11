pub mod call;
pub mod declaration;
pub mod parameter;

pub use call::{FunctionCall, HasFunctionCalls};
pub use declaration::{FunctionDeclaration, HasStandardFunctions};
pub use parameter::{Parameter, HasParameter};
