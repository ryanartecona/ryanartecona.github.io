--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Text.Pandoc.Options
import           Text.Pandoc.Definition
import           Flow
import           Data.Char (toLower)
import           Data.Monoid ((<>))
import           Hakyll
import           Hakyll.Web.Sass (sassCompiler)
import qualified System.FilePath as FP
import           System.Process (readProcess)


--------------------------------------------------------------------------------
main :: IO ()
main = hakyll $ do
    match ("images/*" .||. "downloads/*" .||. "resume.pdf") $ do
      route   idRoute
      compile copyFileCompiler

    match "css/*.css" $ do
      route   idRoute
      compile copyFileCompiler

    match "css/main.scss" $ do
      route $ setExtension "css"
      compile sassCompiler

    match ("_layouts/*.html" .||. "_includes/*") $ do
      compile templateCompiler

    match "_posts/*" $ do
      route $ setExtension "html"
      compile $ getResourceBody
        >>= saveSnapshot "source"
        >>  myPandocCompiler
        >>= loadAndApplyTemplate "_layouts/post.html" postCtx
        >>= loadAndApplyTemplate "_layouts/default.html" postCtx
        >>= relativizeUrls

    match "about.html" $ do
      route $ customRoute $ \t -> t |> toFilePath |> FP.dropExtension |> (FP.</> "index.html")
      compile $ myPandocCompiler
        >>= loadAndApplyTemplate "_layouts/default.html" defaultContext
        >>= relativizeUrls

    match "index.html" $ do
      route $ idRoute
      compile $ do
        posts <- recentFirst =<< loadAllSnapshots "_posts/*" "source"
        let indexCtx = mconcat [
              listField "posts" postCtx (return posts) ,
              defaultContext ]
        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "_layouts/default.html" indexCtx
          >>= relativizeUrls

    -- create ["archive.html"] $ do
    --     route idRoute
    --     compile $ do
    --         posts <- recentFirst =<< loadAll "posts/*"
    --         let archiveCtx =
    --                 listField "posts" postCtx (return posts) `mappend`
    --                 constField "title" "Archives"            `mappend`
    --                 defaultContext
    --         makeItem ""
    --             >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
    --             >>= loadAndApplyTemplate "templates/default.html" archiveCtx
    --             >>= relativizeUrls


--------------------------------------------------------------------------------
-- Helpers and Context fields
dateCtx :: Context String
dateCtx = dateField "date" "%B %e, %Y"

postCtx :: Context String
postCtx =
    dateCtx
    <> defaultContext

myPandocCompiler :: Compiler (Item String)
myPandocCompiler =
    pandocCompilerWithTransformM defReadOpts defWriteOpts pygmentize
  where
    defReadOpts = defaultHakyllReaderOptions
    defWriteOpts = defaultHakyllWriterOptions {writerEmailObfuscation = NoObfuscation}


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
