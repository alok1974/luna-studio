#!/bin/bash

travis_wait 30 stack build --stack-yaml=build/backend/stack.yaml --verbose --no-terminal --only-dependencies --install-ghc --test -j2 --ghc-options=-j2 --ghc-options=-O2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS
stack build --stack-yaml=luna-studio/stack.yaml --no-terminal --only-dependencies --install-ghc --fast -j2 --ghc-options=-j2 --ghc-options=-O2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS
stack build --stack-yaml=runner/stack.yaml --only-dependencies --no-terminal --install-ghc --fast -j2 --ghc-options=-j2 --ghc-options=-O2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS
