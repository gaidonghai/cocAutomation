#Requires AutoHotkey v2.0
#SingleInstance force

if false {
    Var1 := "[1,'works']"
    MsgBox(Str2Object(Var1)[2])

    Var2 := array("test", -1, "[2,3", map("key", "va```'lu```"e"), [4, "ss"], { x: [4, "ss"], y: 4 })
    MsgBox(Object2Str(Var2))
}

Object2Str(Var) {
    Output := ""
    if !(Type(Var) ~= "Map|Array|Object|String|Number|Integer|Float") {
        throw Error("Object type not supported.", -1, Format("<Object at 0x{:p}>", Type(Var)))
    }
    if (Type(Var) = "Array") {
        Output .= "["
        For Index, Value in Var {
            Output .= ((Index = 1) ? "" : ",") Object2Str(Value)
        }
        Output .= "]"
    } else if (Type(Var) = "Map") {
        Output .= "Map("
        For Key, Value in Var {
            Output .= ((A_index = 1) ? "" : ",") Key "," Object2Str(Value)
        }
        Output .= ")"
    } else if (Type(Var) = "Object") {
        Output .= "{"
        For Key, Value in Var.Ownprops() {
            Output .= ((A_index = 1) ? "" : ",") Key ":" Object2Str(Value)
        }
        Output .= "}"
    } else if (Type(Var) = "String") {

        ; Quotes := InStr(Var,"'") ? '"' : "'"
        ; MsgBox(Var "`n" Quotes )
        Output := IsNumber(Var) ? Var : InStr(Var, "'") ? '"' Var '"' : "'" StrReplace(Var, "'", "``'") "'"
    } else {
        Output := Var
    }
    if (Type(Var) ~= "Map|Array" and ObjOwnPropCount(Var) > 0) {
        Output .= "{"
        For Key, Value in Var.Ownprops() {
            Output .= ((A_index = 1) ? "" : ",") Key ":" Object2Str(Value)
        }
        Output .= "}"
    }

    Return Output
}

Str2Object(Input) {
    Input := Trim(Input)
    Skipnext := 0
    aLevel := Array()
    Var := ""

    if Regexmatch(Input, "i)^(\[|array\().*") {
        EndArrayChar := "]"
        if Regexmatch(Input, "i)^array\(.*") {
            EndArrayChar := ")"
            Input := RegExReplace(Input, "i)^array\((.*)", "[$1")
        }
        aInput := StrSplit(Input)
        Output := Array()

        aLevel.Push(EndArrayChar)

        Loop aInput.Length {
            if (A_index = 1 and aInput[A_index] = "[") {
                continue
            } else if (Skipnext = 1) {
                Skipnext := 0
            } else if (aInput[A_index] ~= "``") {
                Skipnext := 1
            } else if (aLevel.length > 1 and aLevel[aLevel.length] = aInput[A_index]) {
                aLevel.RemoveAt(aLevel.length)
            } else if (aLevel[aLevel.length] = '"' or aLevel[aLevel.length] = "'") {
                ; skip
            } else if (aInput[A_index] = '"') {
                aLevel.Push('"')
                ; continue
            } else if (aInput[A_index] = "'") {
                aLevel.Push("'")
                ; continue
            } else if (aInput[A_index] = '{') {
                aLevel.Push('}')
            } else if (aInput[A_index] = '[') {
                aLevel.Push(']')
            } else if (aInput[A_index] = '(') {
                aLevel.Push(')')
            } else if (aLevel.length = 1 and aInput[A_index] = ",") {
                Output.Push(Str2Object(Var))
                Var := ""
                continue
            } else if (aLevel.length = 1 and aInput[A_index] = aLevel[aLevel.length]) {
                Output.Push(Str2Object(Var))
                Rest := Trim(Substr(Input, A_Index + 1))
                if (Rest != "") {
                    ; Hack, if an object is defined afther the array, add them as properties
                    Output := AddProperties(Output, Rest)
                }
                break
            }
            if (StrLen(Var) = 0 and aInput[A_index] = " ") {
                continue
            }
            Var .= aInput[A_index]
        }
    } else if Regexmatch(Input, "i)^(map\().*") {
        Output := Map()
        Input := RegExReplace(Input, "i)^map\((.*)", "$1")
        aInput := StrSplit(Input)

        Key := ""

        aLevel.Push(")")
        Loop aInput.Length {
            if (aLevel.length > 1 and aLevel[aLevel.length] = aInput[A_index]) {
                aLevel.RemoveAt(aLevel.length)
            } else if (Skipnext = 1) {
                Skipnext := 0
            } else if (aInput[A_index] ~= "``") {
                Skipnext := 1
            } else if (aLevel.length > 1 and aLevel[aLevel.length] = '"' or aLevel[aLevel.length] = "'") {
                ; skip
            } else if (aInput[A_index] = '"') {
                aLevel.Push('"')
            } else if (aInput[A_index] = "'") {
                aLevel.Push("'")
            } else if (aInput[A_index] = '{') {
                aLevel.Push('}')
            } else if (aInput[A_index] = '[') {
                aLevel.Push(']')
            } else if (aInput[A_index] = '(') {
                aLevel.Push(')')
            } else if (aLevel.length = 1 and aInput[A_index] = ",") {
                if (Key = "") {
                    Key := RegexReplace(Var, "`"|'")
                } else {
                    Output[Key] := Str2Object(Var)
                    Key := ""
                }
                Var := ""
                continue
            } else if (aLevel.length = 1 and aInput[A_index] = aLevel[aLevel.length]) {
                if (Key = "") {
                    Key := RegexReplace(Var, "`"|'")
                } else {
                    Output[Key] := Str2Object(Var)
                    Key := ""
                }
                Rest := Trim(Substr(Input, A_Index + 1))
                if (Rest != "") {
                    ; Hack, if an object is defined afther the map, add them as properties
                    Output := AddProperties(Output, Rest)
                }
                break
            }
            if (StrLen(Var) = 0 and aInput[A_index] = " ") {
                continue
            }
            Var .= aInput[A_index]
        }
    } else if Regexmatch(Input, "i)^({).*") {
        Output := Object()
        Input := RegExReplace(Input, "i)^{(.*)", "$1")
        aInput := StrSplit(Input)

        Key := ""

        aLevel.Push("}")

        Loop aInput.Length {
            if (aLevel.length > 1 and aLevel[aLevel.length] = aInput[A_index]) {
                aLevel.RemoveAt(aLevel.length)
            } else if (Skipnext = 1) {
                Skipnext := 0
            } else if (aInput[A_index] ~= "``") {
                Skipnext := 1
            } else if (aLevel.length > 1 and aLevel[aLevel.length] = '"' or aLevel[aLevel.length] = "'") {
                ; skip
            } else if (aInput[A_index] = '"') {
                aLevel.Push('"')
            } else if (aInput[A_index] = "'") {
                aLevel.Push("'")
            } else if (aInput[A_index] = '{') {
                aLevel.Push('}')
            } else if (aInput[A_index] = '[') {
                aLevel.Push(']')
            } else if (aInput[A_index] = '(') {
                aLevel.Push(')')
            } else if (aLevel.length = 1 and aInput[A_index] = ":") {
                Key := Trim(Var)
                Var := ""
                continue
            } else if (aLevel.length = 1 and aInput[A_index] = ",") {
                Output.%Key% := Str2Object(Var)
                Var := ""
                continue
            } else if (aLevel.length = 1 and aInput[A_index] = aLevel[aLevel.length]) {
                Output.%Key% := Str2Object(Var)
                Rest := Trim(Substr(Input, A_Index + 1))
                if (Rest != "") {
                    MsgBox(Rest)
                }
                break
            }
            if (StrLen(Var) = 0 and aInput[A_index] = " ") {
                continue
            }
            Var .= aInput[A_index]
        }
    } else {
        ;
        Output := RegExReplace(Input, '^\"(.*)\"$', "$1", &Count)
        if (Count = 0) {
            Output := RegExReplace(Input, "^\'(.*)\'$", "$1", &Count)
        }
        OutputDebug(Output)
        Output := Output
    }

    return Output

    AddProperties(Output, PropString) {
        if Regexmatch(PropString, "i)^({).*") {
            ;Output := Object()
            PropString := RegExReplace(PropString, "i)^{(.*)", "$1")
            aInput := StrSplit(PropString)

            Key := ""
            Var := ""

            aLevel := Array()
            aLevel.Push("}")

            Loop aInput.Length {
                if (aLevel.length > 1 and aLevel[aLevel.length] = aInput[A_index]) {
                    aLevel.RemoveAt(aLevel.length)
                } else if (aLevel.length > 1 and aLevel[aLevel.length] = '"' or aLevel[aLevel.length] = "'") {
                    ; skip
                } else if (aInput[A_index] = '"') {
                    aLevel.Push('"')
                } else if (aInput[A_index] = "'") {
                    aLevel.Push("'")
                } else if (aInput[A_index] = '{') {
                    aLevel.Push('}')
                } else if (aInput[A_index] = '[') {
                    aLevel.Push(']')
                } else if (aInput[A_index] = '(') {
                    aLevel.Push(')')
                } else if (aLevel.length = 1 and aInput[A_index] = ":") {
                    Key := Trim(Var)
                    Var := ""
                    continue
                } else if (aLevel.length = 1 and aInput[A_index] = ",") {
                    Output.%Key% := Str2Object(Var)
                    Var := ""
                    continue
                } else if (aLevel.length = 1 and aInput[A_index] = aLevel[aLevel.length]) {
                    Output.%Key% := Str2Object(Var)
                    Rest := Trim(Substr(PropString, A_Index + 1))
                    if (Rest != "") {
                        MsgBox(Rest)
                    }
                    break
                }
                if (StrLen(Var) = 0 and aInput[A_index] = " ") {
                    continue
                }
                Var .= aInput[A_index]
            }
        }
        return output
    }
}