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

-- Discuss how awkward it is to andThen multiple parsers due to tuples

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

start with return an empty [] into a parsers for the base case
Explain why andThen won't work here
Lead into lift2

```haskell
sequenceP :: [Parser a] -> Parser [a]
sequenceP [] = Parser $ \input -> ([], input)
sequenceP (p : rest) = lift2 (\p r -> p : r) p (sequenceP rest)
```


### Sample Data for sequenceP

```haskell
let p1 = sequenceP [lowercase, uppercase, digit, character]
runParser p1 "aB1*AF"
runParser p1 "1AB1*AF" -- Show failure
runParser p1 ""        -- Show failure
```


## Matching a String parser

sequenceP with characters is hard to work with

```haskell
sequenceP [is 'z', is 'e', is 'n']
```

we want an easier way

show how String is actually a [Char]

```haskell
-- stringP :: [Char] -> Parser [Char]
stringP :: String -> Parser String
stringP chars = sequenceP (map is chars)
```

### Sample Data for stringP

```haskell
runParser (stringP "zendesk") "zendesk is cool"
runParser (stringP "zendesk") ""
```

---


## Change the value of an existing parser


Use andThen as an example

```haskell
let p1 = character `andThen` character
:t p1 -- p1 :: Parser (Char, Char)
```

Parser (Char, Char) -> Parser String

Why not just use lift2 ?


```haskell
mapP :: (a -> b) -> Parser a -> Parser b
mapP f parserA =
    Parser $ \input ->
        case runParser parserA input of
            Left e -> Left e
            Right (a, rest) -> Right (f a, rest)
```

### Sample Data for mapP

```haskell
let p1 = character `andThen` character
:t p1 -- p1 :: Parser (Char, Char)
let p2 = mapP (\(c1, c2) -> c1  : c2 : []) p1
:t p2
runParser p2 "ABCD"

let p2 = mapP (\(c1, c2) -> c2  : c1 : []) p1
runParser p2 "ABCD"
```


## Running a parser as many times as possible

Get as many digits as possible

```haskell
many :: Parser a -> Parser [a]
many parserA =
    let fallback = pureP [] -- we can use pureP
    in lift2 (\p r -> p : r) parserA (many parserA) `orElse` fallback
```
We can also define pureP as part of this

```haskell
pureP :: a -> Parser a
pureP a = Parser $ \input -> Right (a, input)
```


### Sample Data for many

```haskell
runParser (many digit) "1234543534543ABNCD"
runParser (many digit) "" -- Still passes
```


## Running a parser at least one or more times


```haskell
many1 :: Parser a -> Parser [a]
many1 parserA = lift2 (\p r -> p : r) parserA (many parserA)
```

### Sample Data for many1

```haskell
runParser (many1 digit) "1234543534543ABNCD" -- passes
runParser (many1 digit) "1A234543534543ABNCD" -- fails
runParser (many1 digit) "" -- fails
```


## Ignoring the result of the first parser

```haskell
ignoreFirst :: Parser a -> Parser b -> Parser b
ignoreFirst parserA parserB = lift2 (\_ b -> b) parserA parserB
```


### Sample Data for ignoreFirst

```haskell
let p1 = (many digit) `ignoreFirst` (many lowercase)
runParser p1 "1234234abcdf%#$%@#"
```


## Ignoring the result of the second parser

```haskell
ignoreSecond :: Parser a -> Parser b -> Parser a
ignoreSecond parserA parserB = lift2 (\a _ -> a) parserA parserB
```

### Sample Data for ignoreSecond

```haskell
let p1 = (many digit) `ignoreSecond` (many lowercase)
runParser p1 "1234234abcdf%#$%@#"
```

---


## Convert a String -> Int

```haskell
numbers :: Parser String -> Parser Int
numbers parserStr =
  let convertToInt :: String -> Parser Int
  let convertToInt str =
        case readMaybe str of
          Just n  -> pureP n
          Nothing -> failP $ "Could not convert " <> str <> " into a number"
  in parserString `bindP` convertToInt -- we need something that takes these two things
```

```haskell
bindP :: Parser a -> (a -> Parser b) -> Parser b
bindP parserA f =
  Parser $ \input ->
    case runParser parserA input of
      Left e -> Left e
      Right (a, restA) ->
        let parserB = f a
        in runParser parserB restA
```


### Sample Data for bindP

```haskell
let p1 = many character
:t p1
let p2 = numbers p1
:t p2

runParser p2  "1234" -- success
runParser p2  "1A234" -- failure
runParser p2  "" -- failure
```

## Optionally parsing a value

We want success when the parser does not match

start with the `orElse` case

```haskell
opt :: Parser a -> Parser (Maybe a)
opt parserA =  mapP Just parserA `orElse` pureP Nothing
```

### Sample data for optionally parsing a value

```haskell
let p1 = many1 digit
runParser p1 "1234"    -- Parser (1234)
runParser p1 "ABC1234" -- Failure

runParser (opt p1) "1234"    -- Parser (Just 1234)
runParser (opt p1) "ABC1234" -- Parser Nothing
```

## Partially applying a Parser

```haskell
applyP :: Parser (a -> b) -> Parser a -> Parser b
applyP parserAB parserA = lift2 (\f a -> f a) parserAB parserA
```

### Sample data for partially applying a function within a Parser

```haskell
--- create person
:t Person -- Person :: String -> String -> Int -> Person
Person "Jo" "Blogs" 25

-- partially apply
:t Person "Jo" "Blogs" -- Person "Jo" "Blogs" :: Int -> Person

let nameP = (many space) `ignoreFirst` (many1 (lowercase `orElse` uppercase))
let ageP = (many space) `ignoreFirst` (numbers $ many1 digit)
let personP = (pureP Person) `applyP` nameP `applyP` nameP `applyP` ageP

runParser personP "Jo Blogs 25 whatever"

--- Alternatives

let p3 = lift2 Person nameP nameP
:t p3 -- Parser (Int -> Person)

-- we can't use mapP because we need to use two parsers here p3 + ageP
let p4 = lift2 (\f a -> f a) p3 ageP

runParser p4 "Jo Blogs 25 whatever"
```
