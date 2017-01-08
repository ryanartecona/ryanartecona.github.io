{-# LANGUAGE OverloadedStrings #-}
--------------------------------------------------------------------------------
module Main where
import           Text.Pandoc.Options
import           Text.Pandoc.Definition
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
    match ("images/*" .||. "downloads/*" .||. "resume.pdf") $ do
      route   idRoute
      compile copyFileCompiler

    match "css/main.scss" $ do
      route $ setExtension "css"
      compile sassCompiler

    match ("_layouts/*.html" .||. "_includes/*") $ do
      compile templateCompiler

    match "_posts/*" $ do
      route $ foldl composeRoutes idRoute [
        setExtension "html",
        customRoute $ \p -> p |> toFilePath |> (`replaceDirectory` "post/"),
        appendIndex,
        dateFolders]
      compile $ getResourceBody
        >>= saveSnapshot "source"
        >>  myPandocCompiler
        >>= loadAndApplyTemplate "_layouts/post.html" postCtx
        >>= loadAndApplyTemplate "_layouts/default.html" postCtx
        >>= relativizeUrls

    match "about.html" $ do
      route $ customRoute $ \t -> t |> toFilePath |> dropExtension |> (</> "index.html")
      let aboutCtx = navInAbout <> defaultContext
      compile $ myPandocCompiler
        >>= loadAndApplyTemplate "_layouts/default.html" aboutCtx
        >>= relativizeUrls

    match "index.html" $ do
      route $ idRoute
      compile $ do
        posts <- recentFirst =<< loadAllSnapshots "_posts/*" "source"
        let indexCtx = mconcat [
              listField "posts" postCtx (return posts) ,
              navInPosts ,
              defaultContext ]
        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "_layouts/default.html" indexCtx
          >>= relativizeUrls

    redirect "2013/10/26/decorated-anonymous-functions-in-python/index.html"
             "_posts/2013-10-26-decorated-anonymous-functions-in-python.md"

    redirect "2015/05/21/refactoring-in-ruby-in-haskell/index.html"
             "_posts/2015-05-21-refactoring-in-ruby-in-haskell.md"


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

myPandocCompiler :: Compiler (Item String)
myPandocCompiler =
    pandocCompilerWithTransformM defReadOpts defWriteOpts pygmentize
  where
    defReadOpts = defaultHakyllReaderOptions
    defWriteOpts = defaultHakyllWriterOptions {writerEmailObfuscation = NoObfuscation}

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
        >>= loadAndApplyTemplate "_layouts/redirect.html" ctx

--------------------------------------------------------------------------------
-- Highlight with ambient "pygmentize" executable

pygmentize :: Pandoc -> Compiler Pandoc
pygmentize (Pandoc meta bs) = Pandoc meta <$> mapM highlight bs

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
