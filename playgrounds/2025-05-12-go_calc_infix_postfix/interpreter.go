package main

import (
	"fmt"
	"math"
)

type Interpreter Tokens

func (tokens Interpreter) performOp(op, former, latter Token) (result Token) {
	switch op.ContentOperator {
	case '*':
		result.ContentNumber = former.ContentNumber * latter.ContentNumber

	case '/':
		result.ContentNumber = former.ContentNumber / latter.ContentNumber

	case '+':
		result.ContentNumber = former.ContentNumber + latter.ContentNumber

	case '-':
		result.ContentNumber = former.ContentNumber - latter.ContentNumber

	case '^':
		result.ContentNumber = math.Pow(former.ContentNumber, latter.ContentNumber)

	default:
		panic(fmt.Errorf("unsupported operator: %s", string(op.ContentOperator)))
	}

	result.Type = TokenTypeNumber

	return
}

func (interpreter *Interpreter) Evaluate() (result Token, err error) {
	tokens := (*Tokens)(interpreter)
	var operands Tokens

	for _, token := range *tokens {
		switch token.Type {
		default:
			err = fmt.Errorf("unsupported token: %#v", token)
			return

		case TokenTypeNumber:
			operands.Push(token)
			continue

		case TokenTypeOp:
			if operands.Len() < 2 {
				err = fmt.Errorf("not enough operands on the stack to perform an operation: %s", interpreter)
				return
			}

			op := token

			former, _ := operands.Pop()
			latter, _ := operands.Pop()

			token = interpreter.performOp(op, latter, former)

			operands.Push(token)
		}
	}

	result, _ = operands.Pop()

	return
}
