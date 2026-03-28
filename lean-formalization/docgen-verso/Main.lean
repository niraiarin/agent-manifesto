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

def config : Config where
  emitTeX := false
  emitHtmlSingle := true
  emitHtmlMulti := true
  htmlDepth := 4

def main := manualMain (%doc Docs) (config := config)
