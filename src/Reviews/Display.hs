module Reviews.Display
  ( display
  ) where

import Data.Function (on)
import Data.List (groupBy)
import Data.Maybe (catMaybes)
import Data.Text (Text)
import Data.Time
import Prettyprinter
import Prettyprinter.Render.Terminal
import Reviews.GitHub (PR (..), Review (..))
import Reviews.Settings (Settings (..))

display :: Settings -> [PR] -> IO ()
display settings prs = do
  now <- getCurrentTime
  putDoc $
    renderTitle settings (length prs)
    <> renderPRs settings now prs

renderTitle :: Settings -> Int -> Doc AnsiStyle
renderTitle settings count = annotate bold $ 
  countText <+> statusText <+> prsText <> reviewText <> periodText <> hardline <> hardline
  where 
    countText = if count > 0 then pretty count else "No"
    statusText = if settings.includeDrafts then "draft or open" else "open"
    prsText = if count == 1 then "PR" else "PRs"
    reviewText = if settings.reviewRequired then " requiring review" else ""
    periodText = if count == 0 then "." else ":"

renderPRs :: Settings -> UTCTime -> [PR] -> Doc AnsiStyle
renderPRs settings now prs =
  if settings.sortByTime
    then foldMap (renderGroup now)
      $   groupBy ((==) `on` prAuthor) prs
    else
      foldMap 
        (\member -> renderGroup now (filter ((== member) . prAuthor) prs)) 
        settings.members

renderGroup :: UTCTime -> [PR] -> Doc AnsiStyle
renderGroup _ [] = mempty
renderGroup now grp@(first : _) =
  annotate (bold <> color Cyan) (pretty first.prAuthor) <> ":"
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
      branchDoc = annotate (colorDull Green) (pretty prBranch)
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
        <> branchDoc
        <+> urlDoc
        <> detailsLine

whenMaybe :: Bool -> a -> Maybe a
whenMaybe True x = Just x
whenMaybe False _ = Nothing

commas :: [Text] -> Doc AnsiStyle
commas = hsep . punctuate comma . map pretty
