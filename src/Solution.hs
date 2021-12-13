{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE InstanceSigs #-}

module Solution where

import Text.Read (readMaybe)
import qualified Control.Applicative as A


-- Create Parser type
newtype Parser a = Parser { runParser :: String -> Either String (a, String) }


-- Parser for any character
character :: Parser Char
character =
    Parser $ \input ->
        case input of
            []      -> Left "End of input found"
            (c : rest) -> Right (c, rest)

-- What if we want to match a specific character ?
is :: Char -> Parser Char
is char =
    Parser $ \input ->
        case runParser character input of
            Left e -> Left $ "Did not match" <> (show char) <> ", because: " <> e
            Right (x, rest) ->
                if x == char then Right (x, rest)
                else Left $ "Did not match " <> (show char)



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

-- What if we wanted to match character ranges with a single parser?
satisfyP :: String -> (Char -> Bool) -> Parser Char
satisfyP message pred =
    Parser $ \input ->
        case runParser character input of
            Left error -> Left error
            Right (c,rest) ->
                if pred c then Right (c, rest)
                else Left $ (show c) <> " did not match predicate:" <> message


lift2 :: (a -> b -> c) -> Parser a -> Parser b -> Parser c
lift2 f parserA parserB =
    Parser $ \input ->
    let parserAB = parserA `andThen` parserB
    in case runParser parserAB input of
            Left e -> Left e
            Right ((a, b), rest) -> Right (f a b, rest)


pureP :: a -> Parser a
pureP a = Parser $ \input -> Right (a, input)

-- What if we want a run consecutive parses and return list of results back?
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
opt :: Parser a -> Parser (Maybe a)
opt parserA =  mapP Just parserA `orElse` pureP Nothing

-- What if we want to partially apply a function with more than two parameters?
applyP :: Parser (a -> b) -> Parser a -> Parser b
applyP parserAB parserA = lift2 (\f a -> f a) parserAB parserA


-- Extra

-- Create an instance of Functor for Parser
-- replace usages of `mapP` with `fmap`

instance Functor Parser where
    fmap :: (a -> b) -> Parser a -> Parser b
    fmap = mapP

-- Create an instance of Applicative for Parser
-- replace usages of pureP and lift2 with `pure` and `liftA2`
instance Applicative Parser where
    pure :: a -> Parser a
    pure = pureP

    (<*>) :: Parser (a -> b) -> Parser a -> Parser b
    (<*>) = applyP

-- Create an instance of Alternative for Parser
-- replace usages of `orElse` with `<|>`
instance A.Alternative Parser where

    empty :: Parser a
    empty = failP "failed parser"

    (<|>) :: Parser a -> Parser a -> Parser a
    (<|>) = orElse

-- Create an instance of Monad for Parser
-- replace usages of `bindP` with `>>=`
instance Monad Parser where
    return :: a -> Parser a
    return = pure

    (>>=) :: Parser a -> (a -> Parser b) -> Parser b
    (>>=) = bindP


-- Write a parser that parses the following
data Person = Person { name :: String, surname:: String, age :: Int } deriving Show

-- data Person = Person { name :: String, surname :: String, age :: Int}

-- Input: "   Joe Blogs 25 Is a nice guy"
personParser :: Parser Person
personParser =
    let nameP = (many space) `ignoreFirst` (many1 (lowercase `orElse` uppercase))
        ageP = (many space) `ignoreFirst` (numbers $ many1 digit)
    in
        do
            name    <- nameP
            surname <- nameP
            age     <- ageP
            return $ Person name surname age

