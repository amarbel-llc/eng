package main

type TokenType byte

const (
	TokenTypeUnknown = TokenType(iota)
	TokenTypeNumber
	TokenTypeOp
	TokenTypeGroupOpen
	TokenTypeGroupClose
)
