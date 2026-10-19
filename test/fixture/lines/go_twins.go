package main

func main() { println(GoA{}.GoTwin() + GoB{}.GoTwin()) }

type GoA struct{}

type GoB struct{}

func (a GoA) GoTwin() int { return 1 }

func (b GoB) GoTwin() int { return 2 }
