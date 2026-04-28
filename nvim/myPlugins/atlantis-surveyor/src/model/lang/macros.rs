// Generates a static phf map and LanguageConfig impl from a plain data declaration.
#[doc(hidden)]
#[macro_export]
macro_rules! impl_language_syntax_map {
    ($Lang:ty, $map_name:ident, { $($kind:literal => $node_class:expr),* $(,)? }) => {
        static $map_name: phf::Map<&'static str, $crate::model::lang::NodeClass> = phf::phf_map! {
            $($kind => $node_class),*
        };

        impl $crate::model::lang::LanguageConfig for $Lang {
            fn kinds() -> &'static phf::Map<&'static str, $crate::model::lang::NodeClass> {
                &$map_name
            }
        }
    };
}

// Generates two language-specific node enums (Standard + Container) and a
// Resolve impl that dispatches to the correct enum based on NodeClass.
#[doc(hidden)]
#[macro_export]
macro_rules! impl_lang_node_resolver {
    ($Lang:ty, $StdEnum:ident, $CtrEnum:ident) => {
        #[derive(Debug, serde::Serialize)]
        #[serde(tag = "type", rename_all = "snake_case")]
        pub enum $StdEnum {
            Function($crate::model::node::Node<$Lang, $crate::model::supported_nodes::FunctionDeclaration>),
            Call($crate::model::node::Node<$Lang, $crate::model::supported_nodes::FunctionCall>),
            Assignment($crate::model::node::Node<$Lang, $crate::model::supported_nodes::Assignment>),
            Conditional($crate::model::node::Node<$Lang, $crate::model::supported_nodes::ConditionalStatement>),
            Unresolved($crate::model::node::Node<$Lang, $crate::model::node::Unresolved>),
        }

        #[derive(Debug, serde::Serialize)]
        #[serde(tag = "type", rename_all = "snake_case")]
        pub enum $CtrEnum {
            FileRoot($crate::model::node::Node<$Lang, $crate::model::supported_nodes::FileRoot>),
            Body($crate::model::node::Node<$Lang, $crate::model::supported_nodes::Body>),
            ParameterList($crate::model::node::Node<$Lang, $crate::model::supported_nodes::ParameterList>),
            Unresolved($crate::model::node::Node<$Lang, $crate::model::node::Unresolved>),
        }

        impl $crate::model::lang::Resolve for $crate::model::node::Node<$Lang, $crate::model::node::Unknown> {
            type Output = $crate::model::lang::ResolveOutput<$StdEnum, $CtrEnum>;

            fn resolve(self) -> Self::Output {
                use std::marker::PhantomData;
                use $crate::model::lang::{NodeClass, ResolveOutput, SyntaxKind, StructureKind};
                let kind = self.raw.kind.clone();
                match <$Lang as $crate::model::lang::LanguageConfig>::classify(&kind) {
                    Some(NodeClass::Standard(SyntaxKind::Function)) => ResolveOutput::Standard(
                        $StdEnum::Function($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::FunctionDeclaration>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeClass::Standard(SyntaxKind::Call)) => ResolveOutput::Standard(
                        $StdEnum::Call($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::FunctionCall>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeClass::Standard(SyntaxKind::Assignment)) => ResolveOutput::Standard(
                        $StdEnum::Assignment($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::Assignment>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeClass::Standard(SyntaxKind::Conditional)) => ResolveOutput::Standard(
                        $StdEnum::Conditional($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::ConditionalStatement>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeClass::Container(StructureKind::FileRoot)) => ResolveOutput::Container(
                        $CtrEnum::FileRoot($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::FileRoot>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeClass::Container(StructureKind::Body)) => ResolveOutput::Container(
                        $CtrEnum::Body($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::Body>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeClass::Container(StructureKind::ParameterList)) => ResolveOutput::Container(
                        $CtrEnum::ParameterList($crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::supported_nodes::ParameterList>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        })
                    ),
                    Some(NodeClass::Container(StructureKind::ArgumentList)) => ResolveOutput::Container(
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
