module Reviews.Config
  ( Config (..)
  , Opts (..)
  , parseOpts
  , loadConfig
  ) where

import Data.Text (Text)
import Data.Yaml (FromJSON, decodeFileThrow)
import GHC.Generics
import Options.Applicative

data Config = Config
  { org :: Text
  , members :: [Text]
  }
  deriving (Show, Generic)

instance FromJSON Config

newtype Opts = Opts
  { configPath :: FilePath
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

loadConfig :: FilePath -> IO Config
loadConfig = decodeFileThrow

optionsParser :: Parser Opts
optionsParser =
  Opts
    <$> strOption
      ( long "config"
          <> short 'c'
          <> metavar "FILE"
          <> value "config.yaml"
          <> showDefault
          <> help "Path to the configuration file"
      )
