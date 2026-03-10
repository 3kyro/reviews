module Main where

import qualified Data.Text as T
import Reviews.Config
import Reviews.Display
import Reviews.GitHub

main :: IO ()
main = do
  opts <- parseOpts
  config <- loadConfig (configPath opts)
  let config'
        | optsReviewRequired opts = config {reviewRequired = Just True}
        | otherwise = config
  prs <- fetchPRs config'
  displayPRs $ filterByUser (optsUser opts) prs

filterByUser :: Maybe T.Text -> [PR] -> [PR]
filterByUser Nothing = id
filterByUser (Just u) = filter (matches . prAuthor)
  where
    needle = T.toLower u
    matches author = needle `T.isInfixOf` T.toLower author
