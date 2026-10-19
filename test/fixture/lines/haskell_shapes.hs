module Config where

data HsConfig = HsConfig Int

run :: Int
run = hsLimit + hsAttempt 1 + size (HsConfig 3)

hsLimit :: Int
hsLimit = 3

hsAttempt :: Int -> Int
hsAttempt n = n

size :: HsConfig -> Int
size (HsConfig n) = n
