use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum FocusMode {
    Construct,
    Container,
}

impl Default for FocusMode {
    fn default() -> Self {
        Self::Construct
    }
}
