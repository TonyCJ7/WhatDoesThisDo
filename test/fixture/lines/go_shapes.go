package main

func main() { println(GoLimit + GoConfig{}.GoAttempt(1)) }

type GoConfig struct{}

const GoLimit = 3

func (c GoConfig) GoAttempt(n int) int { return n }
