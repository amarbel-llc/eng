package main

import "fmt"

type ValueStringer struct {}

func (s ValueStringer) String() string {
    return "'the best value'"
}

type PointerStringer struct {}

func (s *PointerStringer) String() string {
    return "'the best pointer'"
}

func main() {
    value := ValueStringer{}
    pointerToValue := &ValueStringer{}

    // all output 'the best value'
    fmt.Println(fmt.Stringer(value))
    fmt.Println(fmt.Stringer(pointerToValue))

    pointer := &PointerStringer{}
    valueOfPointer := PointerStringer{}

    // all output 'the best pointer'
    fmt.Println(fmt.Stringer(pointer))
    fmt.Println(fmt.Stringer(valueOfPointer))
}
