module Main where

import qualified Data.Text as T
import Reviews.Settings
import Reviews.Display
import Reviews.GitHub

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
