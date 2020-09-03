{-# LANGUAGE ViewPatterns #-}
module Main where

import System.Random
import Text.Read
import Data.List

-- TODO: This is a very inefficient implementation.
-- What you probably want to do, is use the io-stream library
-- to compose streams in a way so that we only read through
-- the standard input once and newer actually construct
-- a list of lines. The overall structure of the program
-- would probably be something like this:
-- StdInStream | LineStream | ParseStream | StdOutStream
--
-- The detail to keep in mind here, is that the
-- ParseStream somehow has to keep track of the starters
-- and pokemons and then output randomized starters at
-- the end.

main :: IO ()
main = do
    interact (main2 (mkStdGen 0))

main2 :: RandomGen g => g -> String -> String
main2 gen stdin = unlines $ (parse gen) $ lines $ stdin

parse :: RandomGen g => g -> [String] -> [String]
parse gen l =
    let pokemons = countPokemons l
        rand_lines = zip (randomRs (0, pokemons-1) gen) l
    in map randomizeStarter rand_lines

countPokemons :: [String] -> Int
countPokemons l =
    foldr (\line count -> max count (pokemonCount line)) 0 l

-- Parses ".pokemons[<N>]" and returns `N+1`
pokemonCount :: String -> Int
pokemonCount (stripPrefix ".pokemons[" -> Just suf) =
    let match = break (== ']') suf
    in maybe 0 (* 1) (+ 1 (readMaybe (fst match) :: Maybe Int))
pokemonCount _ = 0

-- Parses ".starters[<N>]=<N2>" and returns ".starters[<N>]=<rand>"
-- If string does not match the above, the string is just returned.
randomizeStarter :: (Int, String) -> String
randomizeStarter (rand, (stripPrefix ".starters[" -> Just suf)) =
    let match = break (== '=') suf
    in ".starters[" ++ (fst match) ++ "=" ++ show rand
randomizeStarter (_, l) = l

