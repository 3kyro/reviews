module Reviews.Settings (
  Settings (..),
  mkSettings,
) where

import Data.Aeson (withObject, (.:), (.:?))
import Data.Maybe (fromMaybe)
import Data.Text (Text)
import Data.Yaml (FromJSON (..), decodeFileThrow)
import Options.Applicative
import System.Directory (XdgDirectory (..), getXdgDirectory)

-- | App setup synthesized from Config, Opts, and defaults
data Settings = Settings
  { org :: Text
  , members :: [Text]
  , user :: Maybe Text
  , search :: Maybe Text
  , reviewRequired :: Bool
  , includeDrafts :: Bool
  , draftsOnly :: Bool
  , sortByTime :: Bool
  }
  deriving (Show)

mkSettings :: IO Settings
mkSettings = do
  Opts{..} <- parseOpts
  Config{..} <- loadConfig optsConfigPath
  pure
    Settings
      { org = cfgOrg
      , members = cfgMembers
      , user = optsUser
      , search = optsSearch
      , reviewRequired = optsReviewRequired || fromMaybe False cfgReviewRequired
      , includeDrafts = optsIncludeDrafts || fromMaybe False cfgIncludeDrafts
      , draftsOnly = optsDraftsOnly || fromMaybe False cfgDraftsOnly
      , sortByTime = optsSortByTime || fromMaybe False cfgSortByTime
      }

data Config = Config
  { cfgOrg :: Text
  , cfgMembers :: [Text]
  , cfgReviewRequired :: Maybe Bool
  , cfgIncludeDrafts :: Maybe Bool
  , cfgDraftsOnly :: Maybe Bool
  , cfgSortByTime :: Maybe Bool
  }
  deriving (Show)

instance FromJSON Config where
  parseJSON = withObject "Config" $ \v ->
    Config
      <$> v .: "org"
      <*> v .: "members"
      <*> v .:? "review_required"
      <*> v .:? "include_drafts"
      <*> v .:? "drafts_only"
      <*> v .:? "sort_by_time"

data Opts = Opts
  { optsConfigPath :: Maybe FilePath
  , optsReviewRequired :: Bool
  , optsIncludeDrafts :: Bool
  , optsDraftsOnly :: Bool
  , optsUser :: Maybe Text
  , optsSearch :: Maybe Text
  , optsSortByTime :: Bool
  }

version :: String
version = "0.4.0.0"

parseOpts :: IO Opts
parseOpts =
  execParser $
    info
      (optionsParser <**> helper <**> versionOption)
      ( fullDesc
          <> progDesc "Show open PRs requiring review from your team"
          <> header "reviews - team PR review checker"
      )

versionOption :: Parser (a -> a)
versionOption =
  infoOption version (long "version" <> short 'v' <> help "Show version")

loadConfig :: Maybe FilePath -> IO Config
loadConfig (Just p) = decodeFileThrow p
loadConfig Nothing = do
  p <- getXdgDirectory XdgConfig "reviews/config.yaml"
  decodeFileThrow p

optionsParser :: Parser Opts
optionsParser =
  Opts
    <$> optional
      ( strOption
          ( long "config"
              <> short 'c'
              <> metavar "FILE"
              <> help "Path to the configuration file (default: ~/.config/reviews/config.yaml)"
          )
      )
    <*> switch
      ( long "required"
          <> short 'r'
          <> help "Only show PRs that still need a review"
      )
    <*> switch
      ( long "drafts"
          <> short 'd'
          <> help "Include draft PRs"
      )
    <*> switch
      ( long "drafts-only"
          <> short 'D'
          <> help "Only show draft PRs"
      )
    <*> optional
      ( strOption
          ( long "user"
              <> short 'u'
              <> metavar "USER"
              <> help "Filter PRs by author (case-insensitive substring match)"
          )
      )
    <*> optional
      ( strOption
          ( long "search"
              <> short 's'
              <> metavar "TEXT"
              <> help "Filter PRs by title (case-insensitive substring match)"
          )
      )
    <*> switch
      ( long "time"
          <> short 't'
          <> help "Sort by time instead of by author"
      )
