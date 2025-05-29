package main

import (
	"fmt"
	"strings"
	"testing"
)

func TestPostfixSuccess(t *testing.T) {
	type testCase struct {
		input    string
		expected Token
	}

	testCases := []testCase{
		{
			input: `1`,
			expected: Token{
				ContentNumber: 1,
			},
		},
		{
			input: `2`,
			expected: Token{
				ContentNumber: 2,
			},
		},
		{
			input: `1 2 + 3 + 4 + 5 +`,
			expected: Token{
				ContentNumber: 15,
			},
		},
		{
			input: `1 2 - 3 / 4 * 5 +`,
			expected: Token{
				ContentNumber: 3.666666666666667,
			},
		},
		{
			input: `8 1 - 3 + 6 * 3 7 + -`,
			expected: Token{
				ContentNumber: 50,
			},
		},
		{
			input: `8 1 - 3 + 6 * 3 7 + 2 * -`,
			expected: Token{
				ContentNumber: 40,
			},
		},
	}

	for _, testCase := range testCases {
		t.Run(
			fmt.Sprintf("%#v", testCase),
			func(t *testing.T) {
				reader := strings.NewReader(testCase.input)

				tokens := make(Tokens, 0)

				parser := (*Parser)(&tokens)

				if err := parser.Parse(reader); err != nil {
					t.Errorf("expected no error but got %s", err)
				}

				interpreter := (*Interpreter)(&tokens)

				actual, err := interpreter.Evaluate()
				if err != nil {
					t.Errorf("expected no error but got %s", err)
				}

				testCase.expected.Type = TokenTypeNumber

				if testCase.expected != actual {
					t.Errorf("expected %#v but got %#v", testCase.expected, actual)
				}
			},
		)
	}
}

func TestPostfixError(t *testing.T) {
	type testCase struct {
		input string
	}

	testCases := []testCase{
		{
			input: `+`,
		},
	}

	for _, testCase := range testCases {
		t.Run(
			fmt.Sprintf("%#v", testCase),
			func(t *testing.T) {
				reader := strings.NewReader(testCase.input)

				tokens := make(Tokens, 0)

				parser := (*Parser)(&tokens)

				if err := parser.Parse(reader); err != nil {
					t.Errorf("expected no error but got %s", err)
				}

				interpreter := (*Interpreter)(&tokens)

				_, err := interpreter.Evaluate()
				if err == nil {
					t.Errorf("expected an error but got none")
				}
			},
		)
	}
}
