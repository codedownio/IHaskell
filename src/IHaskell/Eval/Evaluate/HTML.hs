
module IHaskell.Eval.Evaluate.HTML (htmlify) where

import           Data.Maybe
import           Data.Text as T hiding (concat)
import           GHC.SyntaxHighlighter (tokenizeHaskell)
import qualified GHC.SyntaxHighlighter as SH
import           IHaskell.Display (html)
import           IHaskell.IPython.Types (DisplayData)


htmlify :: String -> DisplayData
htmlify str1 = let
  tokensAndTexts = fromMaybe [] (tokenizeHaskell (T.pack str1))
  spans = ["<span className=\"" <> tokenToClassName token <> "\">" <> T.unpack text <> "</span>" | (token, text) <- tokensAndTexts]
  in
  html $ concat ("<div className=\"code\">" : spans <> ["</div>"])

tokenToClassName :: SH.Token -> String
tokenToClassName SH.KeywordTok = "keyword"
tokenToClassName SH.PragmaTok = "pragma"
tokenToClassName SH.SymbolTok = "symbol"
tokenToClassName SH.VariableTok = "variable"
tokenToClassName SH.ConstructorTok = "constructor"
tokenToClassName SH.OperatorTok = "operator"
tokenToClassName SH.CharTok = "char"
tokenToClassName SH.StringTok = "string"
tokenToClassName SH.IntegerTok = "integer"
tokenToClassName SH.RationalTok = "rational"
tokenToClassName SH.CommentTok = "comment"
tokenToClassName SH.SpaceTok = "space"
tokenToClassName SH.OtherTok = "other"
