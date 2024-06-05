#Requires AutoHotkey v2.0

; Source: https://github.com/Descolada/AHK-v2-libraries/blob/main/Lib/Array.ahk

Array.Prototype.base := Array2

class Array2 {
        /**
     * Applies a function to each element in the array (mutates the array).
     * @param func The mapping function that accepts one argument.
     * @param arrays Additional arrays to be accepted in the mapping function
     * @returns {Array}
     */
     static Map(func, arrays*) {
        if !HasMethod(func)
            throw ValueError("Map: func must be a function", -1)
        for i, v in this {
            bf := func.Bind(v?)
            for _, vv in arrays
                bf := bf.Bind(vv.Has(i) ? vv[i] : unset)
            try bf := bf()
            this[i] := bf
        }
        return this
    }


    static Join(delim:=",") {
        result := ""
        for v in this
            result .= v delim
        return (len := StrLen(delim)) ? SubStr(result, 1, -len) : result
    }

    ;; Returns array of items that exist in A and not in B (A is "this")
    static Subtract(arr) {
        C := []
        for a_app in this {
            for b_app in arr {
                if (a_app == b_app) {
                    continue 2
                }
            }
            C.Push(a_app)
        }
        return C
    }

    IndexOf(Arr, Callback) {
        for item in Arr {
            if Callback(item) == true {
                return A_Index
            }
        }
        return -1
    }
}
