pub trait Resolve {
    type Output;
    fn resolve(self) -> Self::Output;
}

/// The output of resolving a Node<Lang, Unknown>. A position in the tree is
/// either a Construct (direct language construct), a Container (structural grouping),
/// or something Atlantis doesn't recognise.
pub enum ResolveOutput<S, C> {
    Construct(S),
    Container(C),
    Unresolved,
}
