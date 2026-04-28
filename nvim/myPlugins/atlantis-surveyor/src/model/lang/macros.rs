// Generates a static phf map and LanguageConfig impl from a plain data declaration.
#[doc(hidden)]
#[macro_export]
macro_rules! impl_language_syntax_map {
    ($Lang:ty, $map_name:ident, { $($kind:literal => $category:expr),* $(,)? }) => {
        static $map_name: phf::Map<&'static str, $crate::model::lang::NodeCategory> = phf::phf_map! {
            $($kind => $category),*
        };

        impl $crate::model::lang::LanguageConfig for $Lang {
            fn kinds() -> &'static phf::Map<&'static str, $crate::model::lang::NodeCategory> {
                &$map_name
            }
        }
    };
}

// Generates the language-specific node enum and Resolve impl for a standard language.
#[doc(hidden)]
#[macro_export]
macro_rules! impl_lang_node_resolver {
    ($Lang:ty, $NodeEnum:ident) => {
        #[derive(Debug, serde::Serialize)]
        #[serde(tag = "type", rename_all = "snake_case")]
        pub enum $NodeEnum {
            Function($crate::model::node::Node<$Lang, $crate::model::states::FunctionDeclaration>),
            Assignment($crate::model::node::Node<$Lang, $crate::model::states::Assignment>),
            Conditional($crate::model::node::Node<$Lang, $crate::model::states::ConditionalStatement>),
            Unresolved($crate::model::node::Node<$Lang, $crate::model::node::Unresolved>),
        }

        impl $crate::model::lang::Resolve for $crate::model::node::Node<$Lang, $crate::model::node::Unknown> {
            type Output = $NodeEnum;

            fn resolve(self) -> $NodeEnum {
                use std::marker::PhantomData;
                let kind = self.raw.kind.clone();
                match <$Lang as $crate::model::lang::LanguageConfig>::categorise(&kind) {
                    Some($crate::model::lang::NodeCategory::Function) => $NodeEnum::Function(
                        $crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::states::FunctionDeclaration>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }
                    ),
                    Some($crate::model::lang::NodeCategory::Assignment) => $NodeEnum::Assignment(
                        $crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::states::Assignment>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }
                    ),
                    Some($crate::model::lang::NodeCategory::Conditional) => $NodeEnum::Conditional(
                        $crate::model::node::Node {
                            state: <$Lang as $crate::model::node::Extract<$crate::model::states::ConditionalStatement>>::extract(&self.raw),
                            raw: self.raw,
                            _lang: PhantomData,
                        }
                    ),
                    None => $NodeEnum::Unresolved(
                        $crate::model::node::Node {
                            state: $crate::model::node::Unresolved,
                            raw: self.raw,
                            _lang: PhantomData,
                        }
                    ),
                }
            }
        }
    };
}
