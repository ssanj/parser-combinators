{-# LANGUAGE ScopedTypeVariables #-}

module Lib where


-- Create Parser type
newtype Parser a = Parser { runParser :: String -> Either String (a, String) }


-- Parser for any character
character :: Parser Char
character =
    Parser $ \input ->
        case input of
            []      -> Left "End of input found"
            (c : rest) -> Right (c, rest)


-- What if we want to parse consecutive characters?

andThen :: Parser a -> Parser b -> Parser (a, b)
andThen parserA parserB =
    Parser $ \input ->
        case runParser parserA input of
            Left e -> Left e
            Right (a, restA) ->
                case runParser parserB restA of
                    Left e -> Left e
                    Right (b, restB) -> Right ((a, b), restB)


-- What if we want to match a specific character ?
is :: Char -> Parser Char
is char =
    Parser $ \input ->
        case runParser character input of
            Left e -> Left $ "Did not match" <> (show char) <> ", because: " <> e
            Right (x, rest) ->
                if x == char then Right (x, rest)
                else Left $ "Did not match " <> (show char)


-- What if we want to parse alternative characters?
orElse :: Parser a -> Parser a -> Parser a
orElse parserA parserB =
    Parser $ \input ->
        case runParser parserA input of
            Left ea ->
                case runParser parserB input of
                    Left eb -> Left $ ea <> ", " <> eb
                    Right (b, restB) -> Right (b, restB)
            Right (a, restA) -> Right (a, restA)



failP :: Parser a
failP = Parser $ \_ -> Left "parser failed"


-- Can we make choosing alternative parsers easier?
choose :: [Parser a] -> Parser a
choose [] = failP
choose (x: rest) = foldl (\a v -> a `orElse` v) x rest


-- Can we make choosing alternative parsers from a String?
anyOf :: String -> Parser Char
anyOf chars = choose (map is chars)


-- Can we only parse lowercase alphabetic characters?
lowercase :: Parser Char
lowercase = anyOf ['a' .. 'z']

-- Can we only parse lowercase alphabetic characters?
uppercase :: Parser Char
uppercase = anyOf ['A' .. 'Z']

-- Can we only parse digits?
digit :: Parser Char
digit = anyOf ['0' .. '9']

lift2 :: (a -> b -> c) -> Parser a -> Parser b -> Parser c
lift2 f parserA parserB =
    Parser $ \input ->
    let parserAB = parserA `andThen` parserB
    in case runParser parserAB input of
            Left e -> Left e
            Right ((a, b), rest) -> Right (f a b, rest)


pureP :: a -> Parser a
pureP a = Parser $ \input -> Right (a, input)

-- Can we consecutively use a list of parsers?
sequenceP :: [Parser a] -> Parser [a]
sequenceP [] = pureP []
sequenceP (p:rest) = lift2 (:) p (sequenceP rest)


-- What if we want to parse a String?
stringP :: String -> Parser String
stringP chars = sequenceP (map is chars)

-- mapP :: (a -> b) -> Parser a -> Parser b
-- mapP f parserA =
--     Parser $ \input ->
--         case runParser parserA input of
--             Left e -> Left e
--             Right (a, rest) -> Right (f a, rest)


-- What if we want to run a parser as many times as possible?
many :: Parser a -> Parser [a]
many parserA =
    let fallback = pureP []
    in lift2 (:) parserA (many parserA) `orElse` fallback

-- What if we want to run a parser one or more times?
many1 :: Parser a -> Parser [a]
many1 parserA = lift2 (:) parserA (many parserA)


-- What if we want to exclude spaces?
space :: Parser Char
space = is ' '


-- What if we want to ignore the result of the first parser?
ignoreFirst :: Parser a -> Parser b -> Parser b
ignoreFirst parserA parserB = lift2 (\_ b -> b) parserA parserB

ignoreSecond :: Parser a -> Parser b -> Parser a
ignoreSecond parserA parserB = lift2 (\a _ -> a) parserA parserB
