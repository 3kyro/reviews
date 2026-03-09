module Reviews.Display
  ( displayPRs
  ) where

import Data.Function (on)
import Data.List (groupBy, sortOn)
import Data.Maybe (catMaybes)
import Data.Text (Text)
import Data.Time
import Prettyprinter
import Prettyprinter.Render.Terminal
import Reviews.GitHub (PR (..), Review (..))

displayPRs :: [PR] -> IO ()
displayPRs [] = putDoc $ "No open PRs requiring review." <> hardline
displayPRs prs = do
  now <- getCurrentTime
  let grouped =
        groupBy ((==) `on` prAuthor) $
          sortOn prAuthor prs
  putDoc $
    annotate bold (pretty (length prs) <+> "open PR(s) requiring review:")
      <> hardline
      <> hardline
      <> foldMap (renderGroup now) grouped

renderGroup :: UTCTime -> [PR] -> Doc AnsiStyle
renderGroup _ [] = mempty
renderGroup now grp@(first : _) =
  annotate (bold <> color Cyan) (pretty (prAuthor first)) <> ":"
    <> hardline
    <> foldMap (\pr -> renderPR now pr <> hardline) grp

renderPR :: UTCTime -> PR -> Doc AnsiStyle
renderPR now PR{..} =
  let days = floor (diffUTCTime now prCreatedAt / 86400) :: Int
      ageText
        | days == 0 = "today"
        | days == 1 = "1 day ago"
        | otherwise = pretty days <+> "days ago"
      ageColor
        | days < 3 = color Green
        | days < 7 = color Yellow
        | otherwise = color Red
      approvals = [reviewAuthor r | r <- prLatestReviews, reviewState r == "APPROVED"]
      changesReq = [reviewAuthor r | r <- prLatestReviews, reviewState r == "CHANGES_REQUESTED"]
      details =
        catMaybes
          [ whenMaybe (prCommentCount > 0) (pretty prCommentCount <+> "comments")
          , whenMaybe (not (null prReviewRequests)) ("Requested:" <+> commas prReviewRequests)
          , whenMaybe (not (null approvals)) (annotate (color Green) ("Approved by:" <+> commas approvals))
          , whenMaybe (not (null changesReq)) (annotate (color Red) ("Changes requested by:" <+> commas changesReq))
          ]
      urlDoc = annotate (colorDull Blue) (pretty prUrl)
      detailsLine
        | null details = mempty
        | otherwise = hardline <> "    " <> hsep (punctuate " |" details)
   in "  " <> pretty prRepo <+> "#" <> pretty prNumber <+> parens (annotate ageColor ageText)
        <> hardline
        <> "    "
        <> pretty prTitle
        <> hardline
        <> "    "
        <> urlDoc
        <> detailsLine

whenMaybe :: Bool -> a -> Maybe a
whenMaybe True x = Just x
whenMaybe False _ = Nothing

commas :: [Text] -> Doc AnsiStyle
commas = hsep . punctuate comma . map pretty
