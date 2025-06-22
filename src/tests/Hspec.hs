module Main where

import           Control.Monad (when)
import           Data.Maybe (fromMaybe)
import qualified GHC.Paths
import           Prelude
import           System.Directory (doesPathExist, getCurrentDirectory)
import           System.Environment (lookupEnv, setEnv)

import           Test.Hspec

import           IHaskell.Test.Completion (testCompletions)
import           IHaskell.Test.Parser (testParser)
import           IHaskell.Test.Eval (testEval)
import           IHaskell.Test.Hoogle (testHoogle)

main :: IO ()
main = do
  currentDir <- getCurrentDirectory
  packageConfInPlaceExists <- doesPathExist (currentDir ++ "/dist/package.conf.inplace")
  when packageConfInPlaceExists $ do
    ghcPackagePath <- fromMaybe "" <$> lookupEnv "GHC_PACKAGE_PATH"
    setEnv "GHC_PACKAGE_PATH" $ (currentDir ++ "/dist/package.conf.inplace/" ++ ":" ++ ghcPackagePath)

  let ghcLibDir = GHC.Paths.libdir

  hspec $ do
    testParser ghcLibDir
    testEval ghcLibDir
    testCompletions ghcLibDir
    testHoogle
