#!/bin/bash

stack build --stack-yaml=luna-studio/stack.yaml --no-terminal --only-dependencies --install-ghc -j2 --ghc-options=-j2 --ghc-options=-O2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS
stack build --stack-yaml=runner/stack.yaml --only-dependencies --no-terminal --install-ghc -j2 --ghc-options=-j2 --ghc-options=-O2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS


stack build --stack-yaml luna-studio/stack.yaml --no-terminal -j2 --ghc-options=-j2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS
stack build --stack-yaml runner/stack.yaml --no-terminal --copy-bins -j2 --ghc-options=-j2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS
