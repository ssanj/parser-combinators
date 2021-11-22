# Build you a Parser Combinator for Great Good

# Introduction

## What is a parser

> a parser is just a function that consumes less-structured input and produces more-structured output.  
- Alexis King from [Parse Don't Validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)

```haskell
String -> FirstName
```

## What is a parser combinator

- Is partial function from some input to some output (diagram)
- Has a way of signalling failure
- Is an open grammar
- Simple pieces combined to create more advanced grammars
- We parse each term of our grammar by recursively calling the parsers for each sub-term (Recursive Decent)
- Are functions that combine and transform parsers into other parsers


# Let's build!


- [ ] parse any character
  - [ ] failure
- [ ] parse specific character
 - [ ] parse 'A'
 - [ ] parse 'B'
 - [ ] is
- [ ] parse one or another character
  - [ ] orElse
- [ ] parse two consecutive characters
  - [ ] andThen
- [ ] parse from a list of parsers
  - [ ] choose
  - [ ] anyOf
  - [ ] parse lower case
  - [ ] parse digit
  - [ ] parse alphabetic
- [ ] parse a String
  - [ ] pure
  - [ ] apply
  - [ ] liftA2
  - [ ] sequence
- [ ] parse as many characters as possible
  - [ ] many
- [ ] parse one or many characters as possible
  - [ ] many1
- [ ] Making choices based on the result
  - [ ] bind
- [ ] Pull up typeclasses
  - [ ] Functor
  - [ ] Applicative
  - [ ] Monad

# Example using Parsec
