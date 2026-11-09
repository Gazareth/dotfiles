import subprocess
from talon import Module, app

mod = Module()


def _set_windows_volume(volume: int) -> None:
    """Set the Windows master output volume (0-100) via Core Audio IAudioEndpointVolume COM API."""
    import ctypes
    from ctypes import POINTER, Structure, byref, c_float, c_int, c_uint, c_void_p, HRESULT
    from ctypes.wintypes import BYTE, DWORD, WORD

    class GUID(Structure):
        _fields_ = [
            ("Data1", DWORD),
            ("Data2", WORD),
            ("Data3", WORD),
            ("Data4", BYTE * 8),
        ]

    CLSID_MMDeviceEnumerator = GUID(
        0xBCDE0395, 0xE52F, 0x467C, (BYTE * 8)(0x8E, 0x3D, 0xC4, 0x57, 0x92, 0x91, 0x69, 0x2E)
    )
    IID_IMMDeviceEnumerator = GUID(
        0xA95664D2, 0x9614, 0x4F35, (BYTE * 8)(0xA7, 0x46, 0xDE, 0x8D, 0xB6, 0x36, 0x17, 0xE6)
    )
    IID_IAudioEndpointVolume = GUID(
        0x5CDF2C82, 0x841E, 0x4546, (BYTE * 8)(0x97, 0x22, 0x0C, 0xF7, 0x40, 0x78, 0x22, 0x9A)
    )

    def vtable_func(obj, index, restype, *argtypes):
        vtbl = ctypes.cast(obj, POINTER(POINTER(c_void_p))).contents
        func_type = ctypes.WINFUNCTYPE(restype, c_void_p, *argtypes)
        return func_type(vtbl[index])

    scalar = max(0.0, min(1.0, volume / 100.0))

    ole32 = ctypes.windll.ole32
    ole32.CoInitialize(None)
    enumerator = c_void_p()
    device = c_void_p()
    endpoint_volume = c_void_p()
    try:
        # CLSCTX_ALL = 23
        hr = ole32.CoCreateInstance(
            byref(CLSID_MMDeviceEnumerator),
            None,
            23,
            byref(IID_IMMDeviceEnumerator),
            byref(enumerator),
        )
        if hr != 0 or not enumerator.value:
            return

        # 4: IMMDeviceEnumerator::GetDefaultAudioEndpoint(eRender=0, eMultimedia=1, &device)
        hr = vtable_func(enumerator, 4, HRESULT, c_int, c_int, POINTER(c_void_p))(
            enumerator, 0, 1, byref(device)
        )
        if hr != 0 or not device.value:
            return

        # 3: IMMDevice::Activate(IID_IAudioEndpointVolume, CLSCTX_ALL=23, None, &endpoint_volume)
        hr = vtable_func(device, 3, HRESULT, POINTER(GUID), DWORD, c_void_p, POINTER(c_void_p))(
            device, byref(IID_IAudioEndpointVolume), 23, None, byref(endpoint_volume)
        )
        if hr != 0 or not endpoint_volume.value:
            return

        # 7: IAudioEndpointVolume::SetMasterVolumeLevelScalar(scalar, None)
        vtable_func(endpoint_volume, 7, HRESULT, c_float, c_void_p)(
            endpoint_volume, c_float(scalar), None
        )

        # 14: IAudioEndpointVolume::SetMute(bMute, None) — unmute when setting volume > 0
        if volume > 0:
            vtable_func(endpoint_volume, 14, HRESULT, c_int, c_void_p)(
                endpoint_volume, 0, None
            )
    finally:
        if endpoint_volume.value:
            vtable_func(endpoint_volume, 2, c_uint)(endpoint_volume)
        if device.value:
            vtable_func(device, 2, c_uint)(device)
        if enumerator.value:
            vtable_func(enumerator, 2, c_uint)(enumerator)


@mod.action_class
class Actions:
    def media_set_volume(volume: int):
        """Sets the system output volume to a percentage between 0 and 100"""
        clamped = max(0, min(100, int(volume)))
        if app.platform == "windows":
            _set_windows_volume(clamped)
        elif app.platform == "mac":
            subprocess.run(
                ["osascript", "-e", f"set volume output volume {clamped}"],
                check=False,
            )
        elif app.platform == "linux":
            subprocess.run(
                ["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{clamped}%"],
                check=False,
            )
