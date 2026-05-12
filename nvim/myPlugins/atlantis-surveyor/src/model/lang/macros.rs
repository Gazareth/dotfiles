// Generates a static phf map and LanguageConfig impl from a plain data declaration.
// Standard and container entries are in separate sections; the macro wraps each
// in the appropriate NodeKind variant so call sites only name the leaf variant.
#[doc(hidden)]
#[macro_export]
macro_rules! impl_language_syntax_map {
    ($Lang:ty, $map_name:ident, {
        $($kind:literal => $node:ident),* $(,)?
    }) => {
        static $map_name: phf::Map<&'static str, $crate::model::lang::NodeKind> = phf::phf_map! {
            $($kind => $crate::model::lang::NodeKind::$node,)*
        };

        impl $crate::model::lang::LanguageConfig for $Lang {
            fn kinds() -> &'static phf::Map<&'static str, $crate::model::lang::NodeKind> {
                &$map_name
            }
        }
    };
}

// Generates a language-specific node enum and a
// Resolve impl that dispatches to the correct enum based on NodeKind.
#[doc(hidden)]
#[macro_export]
macro_rules! impl_lang_node_resolver {
    ($Lang:ty, $Enum:ident) => {
        #[derive(Debug, serde::Serialize, Clone)]
        #[serde(tag = "type", rename_all = "snake_case")]
        pub enum $Enum {
            Function($crate::model::node::Node<$Lang, $crate::model::supported_nodes::FunctionDeclaration>),
            Call($crate::model::node::Node<$Lang, $crate::model::supported_nodes::FunctionCall>),
            Assignment($crate::model::node::Node<$Lang, $crate::model::supported_nodes::Assignment>),
            Conditional($crate::model::node::Node<$Lang, $crate::model::supported_nodes::ConditionalStatement>),
            Parameter($crate::model::node::Node<$Lang, $crate::model::supported_nodes::Parameter>),
            ReturnStatement($crate::model::node::Node<$Lang, $crate::model::supported_nodes::ReturnStatement>),
            FileRoot($crate::model::node::Node<$Lang, $crate::model::supported_nodes::FileRoot>),
            Body($crate::model::node::Node<$Lang, $crate::model::supported_nodes::Body>),
            ParameterList($crate::model::node::Node<$Lang, $crate::model::supported_nodes::ParameterList>),
            ExpressionList($crate::model::node::Node<$Lang, $crate::model::supported_nodes::ExpressionList>),
            Unresolved($crate::model::node::Node<$Lang, $crate::model::node::Unresolved>),
        }

        impl $crate::action::ConstructActions for $Enum {
            fn classification_name(&self) -> String {
                self.node_type_name().to_string()
            }

            fn node_type_name(&self) -> &'static str {
                match self {
                    $Enum::Function(_)    => "Function",
                    $Enum::Call(_)        => "Call",
                    $Enum::Assignment(_)  => "Assignment",
                    $Enum::Conditional(_) => "Conditional",
                    $Enum::Parameter(_)   => "Parameter",
                    $Enum::ReturnStatement(_) => "ReturnStatement",
                    $Enum::FileRoot(_)      => "FileRoot",
                    $Enum::Body(_)          => "Body",
                    $Enum::ParameterList(_) => "ParameterList",
                    $Enum::ExpressionList(_) => "ExpressionList",
                    $Enum::Unresolved(_)  => "Unresolved",
                }
            }

            fn available_actions(&self) -> &'static [&'static str] {
                match self {
                    $Enum::Function(_)        => &["rename"],
                    $Enum::Call(_)            => &["rename"],
                    $Enum::Assignment(_)      => &["rename"],
                    $Enum::Conditional(_)     => &[],
                    $Enum::Parameter(_)       => &["rename"],
                    $Enum::ReturnStatement(_) => &[],
                    $Enum::FileRoot(_)      => &[],
                    $Enum::Body(_)          => &[],
                    $Enum::ParameterList(_) => &[],
                    $Enum::ExpressionList(_) => &[],
                    $Enum::Unresolved(_)      => &[],
                }
            }

            fn keyed_outline_hints(&self) -> Vec<($crate::model::node::NodeRange, &'static str)> {
                let mut hints = vec![];
                let collect = |target: &Option<$crate::model::NavigationTarget>| -> Option<($crate::model::node::NodeRange, &'static str)> {
                    let t = target.as_ref()?;
                    let k = t.key?;
                    Some((t.range.clone(), k))
                };
                match self {
                    $Enum::Function(n) => {
                        if let Some(h) = collect(&n.state.parameters) { hints.push(h); }
                        if let Some(h) = collect(&n.state.body)        { hints.push(h); }
                    }
                    $Enum::Assignment(n) => {
                        if let Some(h) = collect(&n.state.lhs)   { hints.push(h); }
                        if let Some(h) = collect(&n.state.value) { hints.push(h); }
                    }
                    $Enum::Conditional(n) => {
                        if let Some(h) = collect(&n.state.consequence) { hints.push(h); }
                        if let Some(h) = collect(&n.state.alternate)   { hints.push(h); }
                    }
                    _ => {}
                }
                hints
            }



            fn outline_exceptions(&self) -> Vec<$crate::model::node::NodeRange> {
                let mut exceptions = vec![];
                match self {
                    $Enum::Function(n) => {
                        if let Some(ref r) = n.state.name_range { exceptions.push(r.clone()); }
                    }
                    $Enum::Call(n) => {
                        if let Some(ref r) = n.state.name_range { exceptions.push(r.clone()); }
                    }
                    _ => {}
                }
                exceptions
            }
        }

        impl $crate::model::lang::Resolve for $crate::model::node::Node<$Lang, $crate::model::node::Unknown> {
            type Output = $Enum;

            fn resolve(self) -> Self::Output {
                use std::marker::PhantomData;
                use $crate::model::lang::NodeKind;
                let kind = self.raw.kind.clone();
                match <$Lang as $crate::model::lang::LanguageConfig>::node_kind(&kind) {
                    Some(NodeKind::Function) =>
                        $Enum::Function($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::FunctionDeclaration>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    Some(NodeKind::Call) =>
                        $Enum::Call($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::FunctionCall>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    Some(NodeKind::Assignment) =>
                        $Enum::Assignment($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::Assignment>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    Some(NodeKind::Conditional) =>
                        $Enum::Conditional($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::ConditionalStatement>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    Some(NodeKind::Parameter) =>
                        $Enum::Parameter($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::Parameter>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    Some(NodeKind::ReturnStatement) =>
                        $Enum::ReturnStatement($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::ReturnStatement>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    Some(NodeKind::FileRoot) =>
                        $Enum::FileRoot($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::FileRoot>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    Some(NodeKind::Body) =>
                        $Enum::Body($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::Body>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    Some(NodeKind::ParameterList) =>
                        $Enum::ParameterList($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::ParameterList>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    Some(NodeKind::ArgumentList) =>
                        $Enum::Unresolved($crate::model::node::Node {
                            state: $crate::model::node::Unresolved,
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    Some(NodeKind::ExpressionList) =>
                        $Enum::ExpressionList($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::ExpressionList>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                    None =>
                        $Enum::Unresolved($crate::model::node::Node {
                            state: $crate::model::node::Unresolved,
                            raw: self.raw,
                            _lang: PhantomData,
                        }),
                }
            }
        }
    };
}
