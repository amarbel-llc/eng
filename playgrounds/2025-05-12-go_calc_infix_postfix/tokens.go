package main

type Tokens []Token

func (tokens Tokens) Len() int {
	return len(tokens)
}

func (tokens Tokens) Swap(i, j int) {
	tokens[i], tokens[j] = tokens[j], tokens[i]
}

func (tokens *Tokens) PeekShift() (token Token, ok bool) {
	if tokens.Len() == 0 {
		return
	}

	ok = true
	token = (*tokens)[0]

	return
}

func (tokens *Tokens) Shift() (token Token, ok bool) {
	token, ok = tokens.PeekShift()

	if !ok {
		return
	}

	*tokens = (*tokens)[1:]

	return
}

func (tokens *Tokens) Peek() (token Token, ok bool) {
	if tokens.Len() == 0 {
		return
	}

	ok = true
	token = (*tokens)[tokens.Len()-1]

	return
}

func (tokens *Tokens) Pop() (token Token, ok bool) {
	if tokens.Len() == 0 {
		return
	}

	ok = true
	token = (*tokens)[tokens.Len()-1]
	*tokens = (*tokens)[:tokens.Len() - 1]

	return
}

func (tokens *Tokens) Push(token Token) {
	*tokens = append(*tokens, token)
}
