{-# LANGUAGE QuasiQuotes #-}

module Reviews.GitHub
  ( PR (..)
  , Review (..)
  , fetchPRs
  ) where

import Control.Applicative ((<|>))
import Data.Aeson
import Data.Aeson.Types (Parser)
import qualified Data.ByteString.Lazy as LBS
import Data.Text (Text)
import qualified Data.Text as T
import Data.Text.Encoding (encodeUtf8)
import Data.Time (UTCTime)
import NeatInterpolation (trimming)
import Reviews.Config (Config (..))
import System.Exit
import System.Process

data Review = Review
  { reviewAuthor :: Text
  , reviewState :: Text
  }
  deriving (Show)

instance FromJSON Review where
  parseJSON = withObject "Review" $ \v ->
    Review
      <$> parseAuthorLogin v
      <*> v .: "state"

parseAuthorLogin :: Object -> Parser Text
parseAuthorLogin v = (v .: "author" >>= (.: "login")) <|> pure "unknown"

newtype ReviewRequest = ReviewRequest {rrLogin :: Text}

instance FromJSON ReviewRequest where
  parseJSON = withObject "ReviewRequest" $ \v -> do
    reviewer <- v .: "requestedReviewer"
    ReviewRequest <$> ((reviewer .: "login") <|> (reviewer .: "name"))

data PR = PR
  { prNumber :: Int
  , prTitle :: Text
  , prUrl :: Text
  , prAuthor :: Text
  , prRepo :: Text
  , prCreatedAt :: UTCTime
  , prCommentCount :: Int
  , prReviewRequests :: [Text]
  , prLatestReviews :: [Review]
  }
  deriving (Show)

instance FromJSON PR where
  parseJSON = withObject "PR" $ \v ->
    PR
      <$> v .: "number"
      <*> v .: "title"
      <*> v .: "url"
      <*> parseAuthorLogin v
      <*> (v .: "repository" >>= (.: "nameWithOwner"))
      <*> v .: "createdAt"
      <*> (v .: "comments" >>= (.: "totalCount"))
      <*> (map rrLogin <$> (v .: "reviewRequests" >>= (.: "nodes")))
      <*> (v .: "latestReviews" >>= (.: "nodes"))

newtype GQLResponse = GQLResponse {gqlPRs :: [PR]}

instance FromJSON GQLResponse where
  parseJSON = withObject "GQLResponse" $ \v ->
    GQLResponse <$> (v .: "data" >>= (.: "search") >>= (.: "nodes"))

graphqlQuery :: Text
graphqlQuery =
  [trimming|
    query($$q: String!) {
      search(query: $$q, type: ISSUE, first: 100) {
        nodes {
          ... on PullRequest {
            number
            title
            url
            author { login }
            repository { nameWithOwner }
            createdAt
            comments { totalCount }
            reviewRequests(first: 10) {
              nodes {
                requestedReviewer {
                  ... on User { login }
                  ... on Team { name }
                }
              }
            }
            latestReviews(first: 10) {
              nodes {
                author { login }
                state
              }
            }
          }
        }
      }
    }
  |]

fetchPRs :: Config -> IO [PR]
fetchPRs Config{..} = do
  let base = ["org:" <> org, "is:open", "is:pr"]
            ++ ["review:required" | reviewRequired == Just True]
      searchQuery =
        T.unwords $ base ++ map ("author:" <>) members
      ghArgs =
        [ "api"
        , "graphql"
        , "-f"
        , "query=" ++ T.unpack graphqlQuery
        , "-f"
        , "q=" ++ T.unpack searchQuery
        ]
  (code, out, err) <- readProcessWithExitCode "gh" ghArgs ""
  case code of
    ExitFailure _ -> do
      putStrLn $ "gh error: " ++ err
      return []
    ExitSuccess ->
      case eitherDecode (LBS.fromStrict $ encodeUtf8 $ T.pack out) of
        Left e -> do
          putStrLn $ "JSON parse error: " ++ e
          return []
        Right resp -> return (gqlPRs resp)
