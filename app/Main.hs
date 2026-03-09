module Main where

import Reviews.Config
import Reviews.Display
import Reviews.GitHub

main :: IO ()
main = do
  opts <- parseOpts
  config <- loadConfig (configPath opts)
  prs <- fetchPRs config
  displayPRs prs
