module Main where

import Data.Text qualified as T
import Reviews.Display
import Reviews.GitHub
import Reviews.Settings

main :: IO ()
main = do
  settings <- mkSettings
  prs <- fetchPRs settings
  display settings
    . filterBy prAuthor settings.user
    . filterBy prTitle settings.search
    $ prs

filterBy :: (PR -> T.Text) -> Maybe T.Text -> [PR] -> [PR]
filterBy _ Nothing = id
filterBy field (Just needle) = filter (matches . field)
 where
  matches t = T.toLower needle `T.isInfixOf` T.toLower t
