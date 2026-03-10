module Main where

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
  displayPRs prs
