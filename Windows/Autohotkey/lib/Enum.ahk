#Requires AutoHotkey v2.0

class Enum {
    __New(Entries, StartValue := 1) {
        val := StartValue
        for entry in Entries {
            this.%entry% := val
            val += 1
        }
    }
}