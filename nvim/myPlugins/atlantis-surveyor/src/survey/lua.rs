use std::ffi::c_int;

use nvim_oxi::conversion::ToObject;
use nvim_oxi::lua;
use nvim_oxi::serde::Serializer;
use nvim_oxi::Object;
use serde::Serialize;

use super::AtlantisNode;

impl ToObject for AtlantisNode {
    fn to_object(self) -> Result<Object, nvim_oxi::conversion::Error> {
        self.serialize(Serializer::new()).map_err(Into::into)
    }
}

impl lua::Pushable for AtlantisNode {
    unsafe fn push(
        self,
        lstate: *mut lua::ffi::State,
    ) -> Result<c_int, lua::Error> {
        unsafe {
            self.to_object()
                .map_err(lua::Error::push_error_from_err::<Self, _>)?
                .push(lstate)
        }
    }
}
