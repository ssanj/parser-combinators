{-# LANGUAGE ScopedTypeVariables #-}

module Lib where

import Text.Read (readMaybe)


-- Create Parser type
newtype Parser a = Parser { runParser :: String -> Either String (a, String) }


-- TODO: Write example scenarios in comments so you can just copy-paste them into the repl

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



failP :: String -> Parser a
failP error = Parser $ \_ -> Left error


-- Can we make choosing alternative parsers easier?
choose :: [Parser a] -> Parser a
choose [] = failP "parser failed"
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


-- What if we wanted to change the value of an existing parser?
mapP :: (a -> b) -> Parser a -> Parser b
mapP f parserA =
    Parser $ \input ->
        case runParser parserA input of
            Left e -> Left e
            Right (a, rest) -> Right (f a, rest)


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


-- What if we want to change our parser based on a result of a previous parser?
-- Convert a String parser to an Int parser?
-- use `readMaybe :: Read a => String -> Maybe a` from Text.Read
numbers :: Parser String -> Parser Int
numbers parserStr =
    let convertToInt :: String -> Parser Int
        convertToInt str =
            case readMaybe str of
                Just n  -> pureP n
                Nothing -> failP $ "Could not convert " <> str <> " to a number"
    in parserStr `bindP` convertToInt


bindP :: Parser a -> (a -> Parser b) -> Parser b
bindP parserA f =
    Parser $ \input ->
        case runParser parserA input of
            Left e -> Left e
            Right (a, restA) ->
                let parserB = f a
                in runParser parserB restA

-- What if we wanted to optionally match an element without failing?
-- let p1 = many1 digit
-- let p2 = numbers p1
-- runParser p2 "1234"    -- Parser (1234)
-- runParser p2 "ABC1234" -- Failure
--
-- runParser (opt p2) "1234"    -- Parser (Just 1234)
-- runParser (opt p2) "ABC1234" -- Parser Nothing
opt :: Parser a -> Parser (Maybe a)
opt parserA =  mapP Just parserA `orElse` pureP Nothing

-- What if we want to partially apply a function with more than two parameters?
-- lift2 :: (a -> b -> c) -> Parser a -> Parser b -> Parser c
-- mapP        ::(a -> b) -> Parser a -> Parser b
applyP :: Parser (a -> b) -> Parser a -> Parser b
applyP parserAB parserA = parserAB `bindP` (\f -> mapP f parserA)


-- Create an instance of Functor for Parser
-- replace usages of `mapP` with `fmap`

-- Create an instance of Applicative for Parser
-- replace usages of pureP and lift2 with `pure` and `liftA2`

-- Create an instance of Alternative for Parser
-- replace usages of `orElse` with `<|>`

-- Create an instance of Monad for Parser
-- replace usages of `bindP` with `>>=`

-- Write a parser that parses the following
-- > " PERSON1/FeatureD eeee444 [gone] Random weird comments"
