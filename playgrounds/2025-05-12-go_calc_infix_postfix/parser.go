package main

import (
	"bufio"
	"fmt"
	"io"
	"iter"
	"os"
	"strings"
)

type Parser Tokens

func (parser *Parser) Parse(reader io.Reader) (err error) {
	tokens := (*Tokens)(parser)
	var token Token

	for token, err = range parser.Scan(reader) {
		if err != nil {
			return
		}

		tokens.Push(token)
	}

	return
}

func (tokens *Parser) Scan(reader io.Reader) iter.Seq2[Token, error] {
	return func(yield func(Token, error) bool) {
		bufferedReader := bufio.NewReader(reader)

		var isEOF bool
		var token Token

	READ_LOOP:
		for !isEOF {
			var chunk string
			chunk, err := bufferedReader.ReadString(charSeparator)

			if err == io.EOF {
				isEOF = true
				err = nil
			} else if err != nil {
				if !yield(token, err) {
					return
				}
			}

			chunk = strings.TrimSuffix(chunk, stringSeparator)

			if len(chunk) == 0 {
				fmt.Fprintf(os.Stderr, "no characters passed in\n")
				continue READ_LOOP
			}

			if err = token.Set(chunk); err != nil {
				return
			}

			if !yield(token, nil) {
				return
			}
		}

		return
	}
}
