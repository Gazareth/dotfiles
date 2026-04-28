pub trait Resolve {
    type Output;
    fn resolve(self) -> Self::Output;
}

/// The output of resolving a Node<Lang, Unknown>. A position in the tree is
/// either a Standard language construct, a Container structural grouping,
/// or something Atlantis doesn't recognise.
pub enum ResolveOutput<S, C> {
    Standard(S),
    Container(C),
    Unresolved,
}
