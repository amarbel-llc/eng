package main

import (
	"fmt"
	"strings"
	"testing"
)

func TestInfixSuccess(t *testing.T) {
	type testCase struct {
		input    string
		expected Token
	}

	testCases := []testCase{
		{
			input: `1 + 2`,
			expected: Token{
				ContentNumber: 3,
			},
		},
		{
			input: `2`,
			expected: Token{
				ContentNumber: 2,
			},
		},
		{
			input: `1 + 2 + 3 + 4 + 5`,
			expected: Token{
				ContentNumber: 15,
			},
		},
		{
			input: `1 / 2 * 3 + 4 - 5`,
			expected: Token{
				ContentNumber: 0.5,
			},
		},
		{
			input: `1 / 2 * 3 + ( 4 - 5 )`,
			expected: Token{
				ContentNumber: 0.5,
			},
		},
		{
			input: `( ( ( 1 - 2 ) / 3 ) * 4 ) + 5`,
			expected: Token{
				ContentNumber: 3.666666666666667,
			},
		},
		{
			input: `1 + 2 * 3`,
			expected: Token{
				ContentNumber: 7,
			},
		},
		{
			input: `( 1 + 2 ) * 3`,
			expected: Token{
				ContentNumber: 9,
			},
		},
		{
			input: `( 3 * ( 1 + 2 ) ) * 3`,
			expected: Token{
				ContentNumber: 27,
			},
		},
		{
			input: `( 3 * ( 1 + 2 * 2 ) ) * 3`,
			expected: Token{
				ContentNumber: 45,
			},
		},
		{
			input: `( 3 * ( 1 + 2 * 2 ^ 3 ) ) * 3`,
			expected: Token{
				ContentNumber: 153,
			},
		},
		{
			input: `( 3 * ( 1 + ( 2 * 2 ) ^ 3 ) ) * 3`,
			expected: Token{
				ContentNumber: 585,
			},
		},
		{
			input: `( 3 * ( ( 1 + 2 ) * 2 ^ 3 ) ) * 3`,
			expected: Token{
				ContentNumber: 216,
			},
		},
		{
			input: `( 32 * ( ( 1 + 2 ) * 2 ^ 3 ) ) * 3`,
			expected: Token{
				ContentNumber: 2304,
			},
		},
		{
			input: `2 / 3 ^ 4`,
			expected: Token{
				ContentNumber: 0.02,
			},
		},
		{
			input: `1 + 2 / 3 ^ 4`,
			expected: Token{
				ContentNumber: 1.02,
			},
		},
		{
			input: `1 + ( 2 / 3 ) ^ 4`,
			expected: Token{
				ContentNumber: 1.20,
			},
		},
		{
			input: `( 1 + ( 2 / 3 ) ) ^ 4`,
			expected: Token{
				ContentNumber: 7.72,
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

				t.Log(tokens)

				transformer := (*Transformer)(&tokens)

				if err := transformer.TransformToPostfix(parser.Scan(reader)); err != nil {
					t.Errorf("expected no error but got %s", err)
				}

				t.Log(transformer)

				interpreter := (*Interpreter)(&tokens)

				actual, err := interpreter.Evaluate()
				if err != nil {
					t.Errorf("expected no error but got %s", err)
				}

				testCase.expected.Type = TokenTypeNumber

				if testCase.expected.String() != actual.String() {
					t.Errorf("expected %s but got %s", testCase.expected, actual)
				}
			},
		)
	}
}

func TestInfixError(t *testing.T) {
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
