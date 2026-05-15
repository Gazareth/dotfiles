use std::fmt;

/// Errors surfaced by atlantis_surveyor (Atlantis ecosystem).
#[derive(Debug, Clone)]
pub enum AtlantisError {
    NoParser,
    NoNode,
    UnsupportedLanguage,
    Api(String),
    InvalidResponse(String),
}

impl AtlantisError {
    pub fn from_lua_err_code(code: &str) -> Self {
        match code {
            "no_parser" => Self::NoParser,
            "no_node"   => Self::NoNode,
            other       => Self::InvalidResponse(other.to_string()),
        }
    }

    pub fn user_message(&self) -> String {
        match self {
            Self::NoParser            => "no Tree-sitter parser for this buffer".to_string(),
            Self::NoNode              => "no Tree-sitter node at position".to_string(),
            Self::UnsupportedLanguage => "file type not supported by Atlantis".to_string(),
            Self::Api(s)              => format!("nvim api: {s}"),
            Self::InvalidResponse(s)  => format!("invalid probe response: {s}"),
        }
    }
}

impl fmt::Display for AtlantisError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.user_message())
    }
}
