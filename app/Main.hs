module Main where

import Data.Text qualified as T
import Reviews.Display
import Reviews.GitHub
import Reviews.Settings

main :: IO ()
main = do
  settings <- mkSettings
  prs <- fetchPRs settings
  display settings $ filterByUser settings.user prs

filterByUser :: Maybe T.Text -> [PR] -> [PR]
filterByUser Nothing = id
filterByUser (Just u) = filter (matches . prAuthor)
 where
  needle = T.toLower u
  matches author = needle `T.isInfixOf` T.toLower author
