# Build you a Parser Combinator for Great Good

# Introduction

## What is a parser

> a parser is just a function that consumes less-structured input and produces more-structured output.  
- Alexis King from [Parse Don't Validate](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/)

```haskell
String -> FirstName
```

## What is a parser combinator

- Is partial function from some input to some output
- Has a way of signalling failure
- Is an open grammar
- Simple pieces combined to create more advanced grammars
- We parse each term of our grammar by recursively calling the parsers for each sub-term (Recursive Decent)
- Are functions that combine and transform parsers into other parsers
