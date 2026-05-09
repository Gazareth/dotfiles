// Generates a static phf map and LanguageConfig impl from a plain data declaration.
// Standard and container entries are in separate sections; the macro wraps each
// in the appropriate NodeKind variant so call sites only name the leaf variant.
#[doc(hidden)]
#[macro_export]
macro_rules! impl_language_syntax_map {
    ($Lang:ty, $map_name:ident, {
        construct:  { $($std_kind:literal => $std_node:ident),* $(,)? },
        container: { $($ctr_kind:literal => $ctr_node:ident),* $(,)? } $(,)?
    }) => {
        static $map_name: phf::Map<&'static str, $crate::model::lang::NodeKind> = phf::phf_map! {
            $($std_kind => $crate::model::lang::NodeKind::Construct($crate::model::lang::ConstructNode::$std_node),)*
            $($ctr_kind => $crate::model::lang::NodeKind::Container($crate::model::lang::ContainerNode::$ctr_node),)*
        };

        impl $crate::model::lang::LanguageConfig for $Lang {
            fn kinds() -> &'static phf::Map<&'static str, $crate::model::lang::NodeKind> {
                &$map_name
            }
        }
    };
}

// Generates two language-specific node enums (Standard + Container) and a
// Resolve impl that dispatches to the correct enum based on NodeKind.
#[doc(hidden)]
#[macro_export]
macro_rules! impl_lang_node_resolver {
    ($Lang:ty, $StdEnum:ident, $CtrEnum:ident) => {
        #[derive(Debug, serde::Serialize, Clone)]
        #[serde(tag = "type", rename_all = "snake_case")]
        pub enum $StdEnum {
            Function($crate::model::node::Node<$Lang, $crate::model::supported_nodes::FunctionDeclaration>),
            Call($crate::model::node::Node<$Lang, $crate::model::supported_nodes::FunctionCall>),
            Assignment($crate::model::node::Node<$Lang, $crate::model::supported_nodes::Assignment>),
            Conditional($crate::model::node::Node<$Lang, $crate::model::supported_nodes::ConditionalStatement>),
            Parameter($crate::model::node::Node<$Lang, $crate::model::supported_nodes::Parameter>),
            ReturnStatement($crate::model::node::Node<$Lang, $crate::model::supported_nodes::ReturnStatement>),
            Unresolved($crate::model::node::Node<$Lang, $crate::model::node::Unresolved>),
        }

        impl $StdEnum {
            pub fn node_type_name(&self) -> &'static str {
                match self {
                    $StdEnum::Function(_)    => "Function",
                    $StdEnum::Call(_)        => "Call",
                    $StdEnum::Assignment(_)  => "Assignment",
                    $StdEnum::Conditional(_) => "Conditional",
                    $StdEnum::Parameter(_)   => "Parameter",
                    $StdEnum::ReturnStatement(_) => "ReturnStatement",
                    $StdEnum::Unresolved(_)  => "Unresolved",
                }
            }
        }

        #[derive(Debug, serde::Serialize, Clone)]
        #[serde(tag = "type", rename_all = "snake_case")]
        pub enum $CtrEnum {
            FileRoot($crate::model::node::Node<$Lang, $crate::model::supported_nodes::FileRoot>),
            Body($crate::model::node::Node<$Lang, $crate::model::supported_nodes::Body>),
            ParameterList($crate::model::node::Node<$Lang, $crate::model::supported_nodes::ParameterList>),
            Unresolved($crate::model::node::Node<$Lang, $crate::model::node::Unresolved>),
        }

        impl $CtrEnum {
            pub fn node_type_name(&self) -> &'static str {
                match self {
                    $CtrEnum::FileRoot(_)      => "FileRoot",
                    $CtrEnum::Body(_)          => "Body",
                    $CtrEnum::ParameterList(_) => "ParameterList",
                    $CtrEnum::Unresolved(_)    => "Unresolved",
                }
            }
        }

        impl $crate::action::ConstructActions for $StdEnum {
            fn available_actions(&self) -> &'static [&'static str] {
                match self {
                    $StdEnum::Function(_)    => &["jump_to_body", "jump_to_params", "rename", "yank", "delete"],
                    $StdEnum::Call(_)        => &["jump_to_params", "rename", "yank"],
                    $StdEnum::Assignment(_)  => &["jump_lhs", "jump_rhs", "rename", "yank"],
                    $StdEnum::Conditional(_) => &["jump_to_consequence", "jump_to_condition", "yank"],
                    $StdEnum::Parameter(_)       => &["rename", "yank", "delete"],
                    $StdEnum::ReturnStatement(_) => &[],
                    $StdEnum::Unresolved(_)      => &[],
                }
            }
        }

        impl $crate::model::lang::Resolve for $crate::model::node::Node<$Lang, $crate::model::node::Unknown> {
            type Output = $crate::model::lang::ResolveOutput<$StdEnum, $CtrEnum>;

            fn resolve(self) -> Self::Output {
                use std::marker::PhantomData;
                use $crate::model::lang::{NodeKind, ResolveOutput, ConstructNode, ContainerNode};
                let kind = self.raw.kind.clone();
                match <$Lang as $crate::model::lang::LanguageConfig>::node_kind(&kind) {
                    Some(NodeKind::Construct(ConstructNode::Function)) => ResolveOutput::Construct(
                        $StdEnum::Function($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::FunctionDeclaration>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeKind::Construct(ConstructNode::Call)) => ResolveOutput::Construct(
                        $StdEnum::Call($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::FunctionCall>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeKind::Construct(ConstructNode::Assignment)) => ResolveOutput::Construct(
                        $StdEnum::Assignment($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::Assignment>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeKind::Construct(ConstructNode::Conditional)) => ResolveOutput::Construct(
                        $StdEnum::Conditional($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::ConditionalStatement>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeKind::Construct(ConstructNode::Parameter)) => ResolveOutput::Construct(
                        $StdEnum::Parameter($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::Parameter>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeKind::Construct(ConstructNode::ReturnStatement)) => ResolveOutput::Construct(
                        $StdEnum::ReturnStatement($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::ReturnStatement>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeKind::Container(ContainerNode::FileRoot)) => ResolveOutput::Container(
                        $CtrEnum::FileRoot($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::FileRoot>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeKind::Container(ContainerNode::Body)) => ResolveOutput::Container(
                        $CtrEnum::Body($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::Body>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeKind::Container(ContainerNode::ParameterList)) => ResolveOutput::Container(
                        $CtrEnum::ParameterList($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::ParameterList>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeKind::Container(ContainerNode::ArgumentList)) => ResolveOutput::Container(
                        $CtrEnum::Unresolved($crate::model::node::Node {
                            state: $crate::model::node::Unresolved,
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeKind::Container(ContainerNode::ExpressionList)) => ResolveOutput::Container(
                        $CtrEnum::Unresolved($crate::model::node::Node {
                            state: $crate::model::node::Unresolved,
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    None => ResolveOutput::Unresolved,
                }
            }
        }
    };
}
