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
            (c : rest) -> Right (c, rest)
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

During the implementation we realize that we need an pair in the result

```haskell
newtype Parser = Parser { runParser :: String -> Either String (Char, String) }
```

### Sample data for character parser


```haskell
:t andThen

let p1 = character `andThen` character
runParser p1 "ABCD"
runParser p1 "" -- show error
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
