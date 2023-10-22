import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString.Lazy.Char8 as LBS8
import GLua.AG.Token (Region (..))
import qualified GLuaFixer.Interface as GLua
import GLuaFixer.LintMessage (
  Issue (..),
  LintMessage (..),
  Severity (..),
 )
import GLuaFixer.LintSettings (LintSettings, defaultLintSettings)
import Test.Tasty (TestTree, defaultMain, testGroup)
import Test.Tasty.HUnit (testCase, (@=?))
import Text.ParserCombinators.UU.BasicInstances (LineColPos (..))

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests = testGroup "Unit tests" [testQuotedStringWarningPosition]

-- | Regression test for https://github.com/FPtje/GLuaFixer/issues/169
testQuotedStringWarningPosition :: TestTree
testQuotedStringWarningPosition =
  testCase "Assert that the warning is thrown and in the right region" $
    let
      input = "bar = a or b\nfoo = \"\" and \"\" and \"dddd\" || \"[]\""
      expectedRegion = Region (LineColPos 1 27 40) (LineColPos 1 29 42)
      warning = SyntaxInconsistency "||" "or"
      msg = LintMessage LintWarning expectedRegion warning testFilePath
    in
      lintString input @=? [msg]

-- | Helper to lint a string
lintString :: String -> [LintMessage]
lintString input =
  let
    settings = defaultLintSettings
  in
    case GLua.lex settings testFilePath input of
      Left errs -> errs
      Right mTokens -> case GLua.parse settings testFilePath mTokens of
        Left errs -> errs
        Right ast -> GLua.lexiconLint testFilePath settings mTokens <> GLua.astLint testFilePath settings ast

testFilePath :: String
testFilePath = "test input"