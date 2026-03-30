/-
Agent Manifesto - Formal Documentation
Generated with Verso (leanprover/verso)
-/

import VersoManual

import Docs.Overview
import Docs.Ontology
import Docs.Axioms
import Docs.EmpiricalPostulates
import Docs.Principles
import Docs.Observable
import Docs.DesignFoundation

open Verso.Genre Manual

set_option pp.rawOnError true

-- Point to the parent lean-formalization directory as the example project
set_option verso.exampleProject ".."
set_option verso.exampleModule "Manifest.Axioms"

#doc (Manual) "Agent Manifesto: Formal Specification" =>
%%%
authors := ["Agent Manifesto Project"]
shortTitle := "Agent Manifesto"
%%%

This document provides a navigable, hyperlinked view of the Agent Manifesto's
Lean 4 formalization. The project encodes a set of axioms, boundary conditions,
observable variables, and design principles as formal Lean definitions and theorems.

*Project statistics:* 63 axioms, 353 theorems, 0 sorry.

# Structure

The formalization is organized into the following modules:

- *Ontology* (`Manifest.Ontology`) -- Core type definitions: `Session`, `Structure`, `Context`, `Resource`, `Task`, and boundary conditions L1--L6
- *Axioms* (`Manifest.Axioms`) -- Base theory T0: axioms T1--T8 encoding fundamental constraints
- *Empirical Postulates* (`Manifest.EmpiricalPostulates`) -- Empirical postulates E1--E2
- *Observable* (`Manifest.Observable`) -- Observable variables V1--V7 for measurement
- *Principles* (`Manifest.Principles`) -- Derived principles P1--P6
- *DesignFoundation* (`Manifest.DesignFoundation`) -- Design development foundation D1--D14
- *Evolution* (`Manifest.Evolution`) -- Evolution mechanics and improvement tracking

{include 0 Docs.Overview}
{include 0 Docs.Ontology}
{include 0 Docs.Axioms}
{include 0 Docs.EmpiricalPostulates}
{include 0 Docs.Principles}
{include 0 Docs.Observable}
{include 0 Docs.DesignFoundation}
