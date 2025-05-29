package main

import (
	"fmt"
	"iter"
)

type Transformer Tokens

func (transformer *Transformer) TransformToPostfix(
	tokens iter.Seq2[Token, error],
) (err error) {
	transformed := make(Tokens, 0)

	var operators Tokens
	var groupCount int

	var token Token

	for token, err = range tokens {
		switch token.Type {
		case TokenTypeGroupOpen:
			groupCount++
			continue

		case TokenTypeGroupClose:
			groupCount--

			if groupCount < 0 {
				err = fmt.Errorf("unbalanced group: %s", token)
				return
			}

			operator, ok := operators.Pop()

			if ok {
				transformed.Push(operator)
			}

			continue

		case TokenTypeOp:
			lastOperator, _ := transformed.Peek()

			token.OperatorPrecedence += groupCount * 3
			operators.Push(token)

			if lastOperator.Type == TokenTypeOp {
				if lastOperator.OperatorPrecedence < token.OperatorPrecedence {
					transformed.Pop()
					operators.Push(lastOperator)
					operators.Swap(operators.Len()-1, operators.Len()-2)
				}
			}

			continue
		}

		transformed.Push(token)

		if operator, ok := operators.Pop(); ok {
			transformed.Push(operator)
		}
	}

	for {
		if operator, ok := operators.Pop(); ok {
			transformed.Push(operator)
		} else {
			break
		}
	}

	*transformer = Transformer(transformed)

	return
}
