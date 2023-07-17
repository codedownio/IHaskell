{-# LANGUAGE OverloadedStrings #-}

module IHaskell.Eval.Evaluate.HTML (htmlify) where

import           Data.Function ((&))
import qualified Data.List as L
import           Data.Maybe
import           Data.Text as T hiding (concat)
import           GHC.SyntaxHighlighter (tokenizeHaskell)
import qualified GHC.SyntaxHighlighter as SH
import           IHaskell.Display (html)
import           IHaskell.IPython.Types (DisplayData)


htmlify :: String -> DisplayData
htmlify str1 = html $ T.unpack ("<div class=\"code cm-s-jupyter\">" <> spans <> "</div>")
  where
    spans :: Text
    spans = T.intercalate "\n" (fmap renderLine (getLines tokensAndTexts))

    renderLine xs = mconcat ["<span class=\"" <> tokenToClassName token <> "\">" <> escapeHtml text <> "</span>"
                            | (token, text) <- xs]

    tokensAndTexts = fromMaybe [] (tokenizeHaskell (T.pack str1))

    escapeHtml text = text
                    & T.replace "\n" "<br />"

    getLines :: [(SH.Token, Text)] -> [[(SH.Token, Text)]]
    getLines [] = []
    getLines xs = (curLine <> [spaceBoundary]) : getLines (L.tail rest)
      where (curLine, rest) = L.span (/= spaceBoundary) xs

    spaceBoundary = (SH.SpaceTok, "\n")

tokenToClassName :: SH.Token -> Text
tokenToClassName SH.KeywordTok     = "cm-keyword"
tokenToClassName SH.PragmaTok      = "cm-meta"
tokenToClassName SH.SymbolTok      = "cm-atom"
tokenToClassName SH.VariableTok    = "cm-variable"
tokenToClassName SH.ConstructorTok = "cm-variable-2"
tokenToClassName SH.OperatorTok    = "cm-operator"
tokenToClassName SH.CharTok        = "cm-char"
tokenToClassName SH.StringTok      = "cm-string"
tokenToClassName SH.IntegerTok     = "cm-number"
tokenToClassName SH.RationalTok    = "cm-number"
tokenToClassName SH.CommentTok     = "cm-comment"
tokenToClassName SH.SpaceTok       = "cm-space"
tokenToClassName SH.OtherTok       = "cm-builtin"
