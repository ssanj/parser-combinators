# Script

## Create Parser type

```haskell
newtype Parser = Parser { runParser :: String -> Char }
```

## Create a Parser for any character


```haskell
character :: Parser
character = undefined
```


### Implementation for character parser

During the implementation we realize that we need an Either in the result

```haskell
character :: Parser Char
character =
    Parser $ \input ->
        case input of
            []      -> Left "End of input found"
            (c : _) -> Right c
```

new parser type:

```haskell
newtype Parser = Parser { runParser :: String -> Either String Char }
```

### Sample data for character parser


```haskell
:t character
:t runParser

runParser character "ABCD"
```

We notice that the drops the stream and we can't continue from where we left off.

We realise that we need to keep track of the input:

```haskell
newtype Parser = Parser { runParser :: String -> Either String (Char, String) }
```

## Matching on a specific character (1)

```haskell
isA :: Parser
isA =
    Parser $ \input ->
        case runParser character input of
            Left e -> Left $ "Did not match 'A'"
            Right (x, rest) ->
                if x == 'A' then Right (x, rest)
                else Left $ (show x) <> " did not match 'A'"
```

### Sample data for isA

```haskell
:t isA

runParser isA "ABCD"
runParser isA "BCD" -- show error
```

## Matching on a specific character (2)

```haskell
isB :: Parser
isB =
    Parser $ \input ->
        case runParser character input of
            Left e -> Left $ "Did not match 'B'"
            Right (x, rest) ->
                if x == 'B' then Right (x, rest)
                else Left $ (show x) <> " did not match 'B'"
```

### Sample data for isA

```haskell
:t isB

runParser isB "BCD"
runParser isB "CD" -- show error
```


## Matching on a specific character (3)

```haskell
is :: Char -> Parser
is c =
    Parser $ \input ->
        case runParser character input of
            Left e -> Left $ "Did not match " <> (show c)
            Right (x, rest) ->
                if x == c then Right (x, rest)
                else Left $ (show x) <> " did not match " <> (show c)
```

Remove `isA` and `isB`

### Sample data for is

```haskell
:t is

runParser is 'A' "ABCD"
runParser is 'B' "BCD"
runParser is 'B' "CD" -- show error
```


## Implementing a parser for consecutive characters

```haskell
andThen :: Parser a -> Parser b -> Parser (a, b)
andThen parserA parserB =
    Parser $ \input ->
        case runParser parserA input of
            Left e -> Left e
            Right (a, restA) ->
                case runParser parserB restA of
                    Left e -> Left e
                    Right (b, restB) -> Right ((a, b), restB)
```

During the implementation we realize that we need an pair in the result and the result type needs to be polymorphic

```haskell
newtype Parser a = Parser { runParser :: String -> Either String (a, String) }
```

also rewrite character to return `Parser Char`

### Sample data for andThen parser


```haskell
:t andThen

let p1 = character `andThen` character
runParser p1 "ABCD"
runParser p1 "" -- show error
```


## Implementing a parser for alternative characters

```haskell
orElse :: Parser a -> Parser a -> Parser a
orElse parserA parserB =
    Parser $ \input ->
        case runParser parserA input of
            Left ea ->
                case runParser parserB input of
                    Left eb -> Left $ ea <> ", " <> eb
                    Right (b, restB) -> Right (b, restB)
            Right (a, restA) -> Right (a, restA)
```


### Sample data for orElse parser

```haskell
:t orElse

let p1 = (is 'A') `orElse` (is 'B')
runParser p1 "ABCD"
runParser p1 "BACD"
runParser p1 "CE" -- show error
runParser p1 ""   -- show error
```

## Implementing a choosing from a list of parsers

```haskell
choose :: [Parser a] -> Parser a
choose [] = failP "parser failed"
choose (x: rest) = foldl (\a v -> a `orElse` v) x rest
```

### Sample data for orElse parser

```haskell
:t choose

let p1 = choose [is 'A', is 'B']
runParser p1 "ABCD"
runParser p1 "BACD"
runParser p1 "CE" -- show error
runParser p1 ""   -- show error
```


We also need to define failP to handle our error

```haskell
failP :: String -> Parser a
failP error = Parser $ \_ -> Left error
```

## Implementing choosing a character parse from a String


```haskell
anyOf :: String -> Parser Char
anyOf chars = choose (map is chars)
```

### Sample data for anyOf parser

```haskell
:t choose

let p1 = anyOf "ABC"
runParser p1 "ABCD"
runParser p1 "BACD"
runParser p1 "CBAD"
runParser p1 "CE" -- show error
runParser p1 ""   -- show error
```

## Parsing character ranges

```haskell
lowercase :: Parser Char
lowercase = anyOf ['a' .. 'z']
```

```haskel
uppercase :: Parser Char
uppercase = anyOf ['A' .. 'Z']
```

```haskell
digit :: Parser Char
digit = anyOf ['0' .. '9']
```

### Sample data for parsing ranges

```haskell
:t lowercase
:t uppercase
:t digit

runParser lowercase "aBCD"
runParser lowercase "BCD" -- show error

runParser uppercase "BaCD"
runParser uppercase "aCD" -- show error

runParser digit "1ABC"
runParser digit "A1BC" -- show error
```
---

## Running consecutive parsers and returning a list of results

-- Discuss how awkward it is to andThen multiple parsers

### Sample Data for discussion

```haskell
let p1 = lowercase `andThen` uppercase `andThen` digit `andThen` character
:t p1
runParser p1 "aB1AF" -- Right (((('a','B'),'1'),'A'),"F")
```


```haskell
lift2 :: (a -> b -> c) -> Parser a -> Parser b -> Parser c
lift2 f parserA parserB =
    Parser $ \input ->
    let parserAB = parserA `andThen` parserB
    in case runParser parserAB input of
            Left e -> Left e
            Right ((a, b), rest) -> Right (f a b, rest)
```

```haskell
sequenceP :: [Parser a] -> Parser [a]
sequenceP [] = Parser $ \input -> ([], input)
sequenceP (p : rest) = p `andThen` sequenceP rest
```
