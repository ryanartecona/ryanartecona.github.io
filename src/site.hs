{-# LANGUAGE OverloadedStrings #-}
--------------------------------------------------------------------------------
module Main where
import           Text.Pandoc (readDocBook)
import           Text.Pandoc.Options
import           Text.Pandoc.Definition
import           Text.Pandoc.Walk (walkM)
import           Text.Pandoc.Error (PandocError (..))
import           Flow
import           Data.Char (toLower)
import           Data.Monoid ((<>))
import           Hakyll
import           Hakyll.Web.Sass (sassCompiler)
import           System.FilePath
import           System.Process (readProcess)


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match ("images/*" .||. "downloads/*" .||. "resume.pdf" .||. "CNAME") $ do
      route   idRoute
      compile copyFileCompiler

    match "css/main.scss" $ do
      route $ setExtension "css"
      compile sassCompiler

    match ("templates/*.html" .||. "partials/*") $ do
      compile templateCompiler

    match ("post/*.md" .||. "draft/*.md") $ do
      route routePostOrDraft
      compile $ getResourceBody
        >>= saveSnapshot "source"
        >>  myPandocCompiler
        >>= loadAndApplyTemplate "templates/post.html" postCtx
        >>= loadAndApplyTemplate "templates/default.html" postCtx
        >>= relativizeUrls

    match ("post/*.adoc" .||. "draft/*.adoc") $ do
      route routePostOrDraft
      let adocPostCtx = (tableOfContentsField "toc" "pandocSource" (readDocBook myPandocReadOpts)) <> postCtx
      compile $ getResourceBody
        >>= saveSnapshot "source"
        >>  compileAsciidoc
        >>= loadAndApplyTemplate "templates/post.html" adocPostCtx
        >>= loadAndApplyTemplate "templates/default.html" adocPostCtx
        >>= relativizeUrls

    match "about.html" $ do
      route $ customRoute $ \t -> t |> toFilePath |> dropExtension |> (</> "index.html")
      let aboutCtx = navInAbout <> defaultContext
      compile $ myPandocCompiler
        >>= loadAndApplyTemplate "templates/default.html" aboutCtx
        >>= relativizeUrls

    match "index.html" $ do
      route $ idRoute
      compile $ do
        posts <- recentFirst =<< loadAllSnapshots "post/*" "source"
        let indexCtx = mconcat [
              listField "posts" postCtx (return posts) ,
              navInPosts ,
              defaultContext ]
        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/default.html" indexCtx
          >>= relativizeUrls

    redirect "2013/10/26/decorated-anonymous-functions-in-python/index.html"
             "post/2013-10-26-decorated-anonymous-functions-in-python.md"

    redirect "2015/05/21/refactoring-in-ruby-in-haskell/index.html"
             "post/2015-05-21-refactoring-in-ruby-in-haskell.md"


--------------------------------------------------------------------------------
-- Helpers and Context fields

dateCtx :: Context String
dateCtx = dateField "date" "%B %e, %Y"

navInPosts, navInAbout :: Context a
navInPosts = constField "isInPosts" "true"
navInAbout = constField "isInAbout" "true"

postCtx :: Context String
postCtx =
    dateCtx
    <> navInPosts
    <> dropIndexHtml "url"
    <> defaultContext

routePostOrDraft :: Routes
routePostOrDraft = foldl composeRoutes idRoute
  [ setExtension "html"
  , appendIndex
  , dateFolders
  ]

redirect :: Identifier -> Identifier -> Rules ()
redirect fromPath toItem =
  create [fromPath] $ do
    route idRoute
    compile $ do
      item <- (load toItem) :: Compiler (Item String)
      maybeRoute <- item |> itemIdentifier |> getRoute
      r <- maybe (fail "unknown route for redirect target") return maybeRoute
      let ctx = constField "location" r
      makeItem ""
        >>= loadAndApplyTemplate "templates/redirect.html" ctx

--------------------------------------------------------------------------------
-- Pandoc stuff

myPandocReadOpts :: ReaderOptions
myPandocReadOpts = defaultHakyllReaderOptions

myPandocWriteOpts :: WriterOptions
myPandocWriteOpts = defaultHakyllWriterOptions
  { writerEmailObfuscation = NoObfuscation
  }

myPandocCompiler :: Compiler (Item String)
myPandocCompiler =
  pandocCompilerWithTransformM myPandocReadOpts myPandocWriteOpts pygmentize

readPandocWithReader
  :: (String -> Either PandocError Pandoc)
  -> Item String
  -> Compiler (Item Pandoc)
readPandocWithReader reader item = case traverse reader item of
  Left (ParseFailure err) -> fail ("readPandocWithReader: parse failed: " ++ err)
  Left (ParsecError _ err) -> fail ("readPandocWithReader: parse failed: " ++ show err)
  Right compiledItem -> return compiledItem

compileAsciidoc :: Compiler (Item String)
compileAsciidoc =
    getResourceBody
      >>= withItemBody (unixFilter "asciidoc" ["--backend", "docbook", "-"])
      >>= saveSnapshot "pandocSource"
      >>= readPandocWithReader (readDocBook myPandocReadOpts)
      >>= traverse pygmentize
      >>= traverse fixAdmonitions
      >>= return . (writePandocWith myPandocWriteOpts)
  where
    -- Pandoc renders DocBook <important>/<caution>/<note>/<tip> as e.g.
    --   <blockquote><p><strong>Note</strong></p><p>note text here</p></blockquote>
    -- I'd rather have something I can style with CSS, like
    --   <div class="admonition note"><p>note text here</p></div>
    -- See: https://github.com/jgm/pandoc/issues/1456#issuecomment-118939340
    fixAdmonitions :: Pandoc -> Compiler Pandoc
    fixAdmonitions (Pandoc meta bs) = Pandoc meta <$> mapM f bs
      where
        f :: Block -> Compiler Block
        f (BlockQuote (Para [Strong [Str "Note"]] : xs)) = return (Div ("", ["admonition", "note"], []) xs)
        f (BlockQuote (Para [Strong [Str "Tip"]] : xs)) = return (Div ("", ["admonition", "tip"], []) xs)
        f (BlockQuote (Para [Strong [Str "Important"]] : xs)) = return (Div ("", ["admonition", "important"], []) xs)
        f (BlockQuote (Para [Strong [Str "Caution"]] : xs)) = return (Div ("", ["admonition", "caution"], []) xs)
        f (BlockQuote (Para [Strong [Str "Warning"]] : xs)) = return (Div ("", ["admonition", "warning"], []) xs)
        f x = return x

--------------------------------------------------------------------------------
-- Table of Contents

tableOfContentsField :: String                                -- ^ Key to use
                     -> Snapshot                              -- ^ Snapshot to load
                     -> (String -> Either PandocError Pandoc) -- ^ Pandoc reader to use
                     -> Context String                        -- ^ Returns ToC (HTML)
tableOfContentsField key snapshot reader = field key $ \item -> do
    snap <- loadSnapshot (itemIdentifier item) snapshot
    (itemBody <$>) . getTableOfContents $ snap
  where
    tocOptions = myPandocWriteOpts
      { writerTableOfContents=True
      , writerStandalone=True
      , writerTemplate="<div class=\"toc\">$toc$</div>"
      }
    getTableOfContents :: Item String -> Compiler (Item String)
    getTableOfContents item =
      return item
        >>= readPandocWithReader reader
        >>= return . (writePandocWith tocOptions)

--------------------------------------------------------------------------------
-- Highlight with ambient "pygmentize" executable

pygmentize :: Pandoc -> Compiler Pandoc
pygmentize = walkM highlight

highlight :: Block -> Compiler Block
highlight (CodeBlock (_, options, _) code) =
  RawBlock "html" <$> unsafeCompiler (pygments code options)
highlight x = return x

pygments :: String -> [String] -> IO String
pygments code options =
  case options of
    (lang:_) ->
      readProcess "pygmentize" ["-l", toLower <$> lang,  "-f", "html"] code
    _ -> return $ "<div class =\"highlight\"><pre>" ++ code ++ "</pre></div>"


--------------------------------------------------------------------------------
-- Jekyll-style post routing helpers

appendIndex :: Routes
appendIndex = customRoute $
  (\(p, e) -> p </> "index" <.> e) . splitExtension . toFilePath

dropIndexHtml :: String -> Context a
dropIndexHtml key = mapContext transform (urlField key) where
    transform url = case splitFileName url of
                        (p, "index.html") -> takeDirectory p
                        _                 -> url
dateFolders :: Routes
dateFolders =
    gsubRoute "/[0-9]{4}-[0-9]{2}-[0-9]{2}-" $ replaceAll "-" (const "/")
