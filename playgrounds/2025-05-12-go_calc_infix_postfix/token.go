package main

import (
	"fmt"
	"strconv"
	"strings"
)

var operatorPrecedence = map[rune]int{
	'^': 2,
	'*': 1,
	'/': 1,
	'+': 0,
	'-': 0,
}

type Token struct {
	Type               TokenType
	ContentOperator    rune
	OperatorPrecedence int
	ContentNumber      float64
}

func (token *Token) Reset() {
	token.Type = TokenTypeUnknown
	token.ContentOperator = '\x00'
	token.ContentNumber = 0
}

func (token Token) String() string {
	switch token.Type {
	case TokenTypeNumber:
		return fmt.Sprintf("%.2f", token.ContentNumber)

	case TokenTypeOp:
		return string(token.ContentOperator)

	case TokenTypeGroupOpen:
		return "("

	case TokenTypeGroupClose:
		return ")"

	default:
		return fmt.Sprintf("Unknown(%d)", token.Type)
	}
}

func (token *Token) Set(value string) (err error) {
	value = strings.TrimSpace(value)

	switch len(value) {
	case 1:
		var char rune

		for _, char = range value {
			break
		}

		if err = token.setMaybeOperatorOrGroup(value, char); err == nil {
			return
		}

		fallthrough

	default:
		return token.setMaybeLiteral(value)
	}
}

func (token *Token) setMaybeOperatorOrGroup(value string, char rune) (err error) {
	switch char {
	case '/', '+', '*', '-', '^':
		token.Type = TokenTypeOp
		token.ContentOperator = char
		token.OperatorPrecedence = operatorPrecedence[char]

	case '(':
		token.Type = TokenTypeGroupOpen

	case ')':
		token.Type = TokenTypeGroupClose

	default:
		err = fmt.Errorf("unsupported operator: %q", value)
	}

	return
}

func (token *Token) setMaybeLiteral(value string) (err error) {
	if token.ContentNumber, err = strconv.ParseFloat(value, 64); err != nil {
		return
	}

	token.Type = TokenTypeNumber

	return
}
