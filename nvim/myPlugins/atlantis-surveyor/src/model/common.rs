use super::node::{Extract, RawNode};
use super::states::*;

// ── Syntax grouping traits ────────────────────────────────────────────────
//
// A language opts into a group by implementing the relevant marker trait.
// It receives the blanket Extract impl for free.
// If a language's syntax diverges, it simply doesn't implement the marker
// and provides its own Extract impl instead.

/// Languages where functions follow: `[async] function name(...) { body }`
/// or close enough that the same field names apply.
pub trait StandardFunctions {}

/// Languages where assignment follows: `name = value` with no scoping keyword.
pub trait StandardAssignment {}

/// Languages where conditionals follow: `if (condition) { consequent } [else { alternate }]`
pub trait StandardConditionals {}

// ── Convenience bundle ────────────────────────────────────────────────────
//
// CLike bundles all three standard groups for languages that share
// most C-family surface syntax. Implementing CLike satisfies all three
// individual marker traits automatically via the blanket impls below.

pub trait CLike: StandardFunctions + StandardAssignment + StandardConditionals {}

impl<Lang: CLike> StandardFunctions for Lang {}
impl<Lang: CLike> StandardAssignment for Lang {}
impl<Lang: CLike> StandardConditionals for Lang {}

// ── Blanket Extract impls ─────────────────────────────────────────────────
//
// These are the shared extraction implementations. They run for any language
// that has opted into the corresponding syntax group.

impl<Lang: StandardFunctions> Extract<FunctionDeclaration> for Lang {
    fn extract(raw: &RawNode) -> FunctionDeclaration {
        FunctionDeclaration {
            name: raw.field_text("name"),
            is_async: raw.has_field("async"),
            // Body and parameters are kept as opaque RawNodes.
            // Atlantis resolves them fresh if the user navigates in.
            parameters: raw.field("parameters").cloned().unwrap_or_else(|| raw.placeholder("parameters")),
            body: raw.field("body").cloned().unwrap_or_else(|| raw.placeholder("body")),
        }
    }
}

impl<Lang: StandardAssignment> Extract<Assignment> for Lang {
    fn extract(raw: &RawNode) -> Assignment {
        Assignment {
            name: raw.field_text("name"),
            is_local_binding: false,
            value: raw.field("value").cloned().unwrap_or_else(|| raw.placeholder("value")),
        }
    }
}

impl<Lang: StandardConditionals> Extract<ConditionalStatement> for Lang {
    fn extract(raw: &RawNode) -> ConditionalStatement {
        ConditionalStatement {
            condition: raw.field("condition").cloned().unwrap_or_else(|| raw.placeholder("condition")),
            consequent: raw.field("consequence").cloned().unwrap_or_else(|| raw.placeholder("consequence")),
            alternate: raw.field("alternative").cloned(),
        }
    }
}
