module Reviews.Config
  ( Config (..)
  , Opts (..)
  , parseOpts
  , loadConfig
  ) where

import Data.Aeson ((.:), (.:?), withObject)
import Data.Text (Text)
import Data.Yaml (FromJSON (..), decodeFileThrow)
import Options.Applicative
import System.Directory (getXdgDirectory, XdgDirectory(..))

data Config = Config
  { org :: Text
  , members :: [Text]
  , reviewRequired :: Maybe Bool
  }
  deriving (Show)

instance FromJSON Config where
  parseJSON = withObject "Config" $ \v ->
    Config
      <$> v .: "org"
      <*> v .: "members"
      <*> v .:? "review_required"

newtype Opts = Opts
  { configPath :: Maybe FilePath
  }

parseOpts :: IO Opts
parseOpts =
  execParser $
    info
      (optionsParser <**> helper)
      ( fullDesc
          <> progDesc "Show open PRs requiring review from your team"
          <> header "reviews - team PR review checker"
      )

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
