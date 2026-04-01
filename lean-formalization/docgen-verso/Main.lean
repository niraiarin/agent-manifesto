/-
Main entry point for Verso documentation generation.
-/

import Std.Data.HashMap
import VersoManual

import Docs

open Verso Doc
open Verso.Genre Manual

open Std (HashMap)

open Docs

open Verso.Output in
def graphViewLink : Html :=
  .tag "a"
    #[ ("href", "/graph-view/")
     , ("style", "position:fixed;bottom:12px;right:12px;z-index:50;padding:8px 16px;background:#16213e;color:#4ea8de;border:1px solid #0f3460;border-radius:6px;font-size:13px;text-decoration:none;font-family:monospace;")
     , ("target", "_blank")
    ]
    (.text true "📊 Graph View")

def config : Config where
  emitTeX := false
  emitHtmlSingle := true
  emitHtmlMulti := true
  htmlDepth := 4
  extraContents := #[graphViewLink]

def main := manualMain (%doc Docs) (config := config)
