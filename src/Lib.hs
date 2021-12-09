{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE InstanceSigs        #-}

module Lib where


-- Create Parser type


-- Parser for any character


-- What if we want to match a specific character ?


-- What if we want to parse consecutive characters?


-- What if we want to parse alternative characters?


-- Can we make choosing alternative parsers easier?


-- Can we make choosing alternative parsers from a String?


-- Can we only parse lowercase alphabetic characters?


-- Can we only parse uppercase alphabetic characters?


-- Can we only parse digits?


-- What if we wanted to match character ranges with a single parser?


-- End of Part 1


-- What if we want a run consecutive parses and return list of results back?


-- What if we want to parse a String?


-- What if we wanted to change the value of an existing parser?


-- What if we want to run a parser as many times as possible?

-- What if we want to run a parser one or more times?


-- What if we want to exclude spaces?

-- What if we want to ignore the result of the first parser?


-- End of Part 2


-- What if we want to change our parser based on a result of a previous parser?
-- Convert a String parser to an Int parser?
-- use `readMaybe :: Read a => String -> Maybe a` from Text.Read


-- What if we wanted to optionally match an element without failing?

-- What if we want to partially apply a function with more than two parameters?


-- Write a parser that parses the following
-- data Person = Person { name :: String, surname:: String, age :: Int } deriving Show

-- Extra

-- Create an instance of Functor for Parser
-- replace usages of `mapP` with `fmap`

-- Create an instance of Applicative for Parser
-- replace usages of pureP and lift2 with `pure` and `liftA2`

-- Create an instance of Alternative for Parser
-- replace usages of `orElse` with `<|>`

-- Create an instance of Monad for Parser
-- replace usages of `bindP` with `>>=`
