package main

import (
	"fmt"
	"io"
	"os"
)

var (
	charSeparator   = byte(' ')
	stringSeparator = string(charSeparator)
)

func main() {
	parseTokens(os.Stdin)
}

func parseTokens(reader io.Reader) {
	tokens := make(Tokens, 0)
	parser := (*Parser)(&tokens)

	transformer := (*Transformer)(&tokens)

	if err := transformer.TransformToPostfix(parser.Scan(reader)); err != nil {
		panic(err)
	}

	interpreter := Interpreter(tokens)

	var result Token

	{
		var err error

		if result, err = interpreter.Evaluate(); err != nil {
			panic(err)
		}
	}

	fmt.Println(result)
}
