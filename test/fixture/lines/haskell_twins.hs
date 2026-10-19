module Twins where

run :: Int
run = hsTwin 1
  where
    hsTwin :: Int -> Int
    hsTwin n = n

other :: Int
other = hsTwin 2
  where
    hsTwin :: Int -> Int
    hsTwin n = n + 1
