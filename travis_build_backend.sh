#!/bin/bash
set -x

# Install GHC and build dependencies
timeout 50m stack build --stack-yaml=build/backend/stack.yaml --verbose --no-terminal --only-dependencies --install-ghc --test -j2 --ghc-options=-j2 --ghc-options=-O2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS
ret=$?
case "$ret" in
  0)
    # continue
    ;;
  124)
    echo "Timed out while installing dependencies."
    echo "Try building again by pushing a new commit."
    exit 1
    ;;
  *)
    echo "Failed to install dependencies; stack exited with $ret"
    exit "$ret"
    ;;
esac

# Build your project

stack build --stack-yaml build/backend/stack.yaml --no-terminal --copy-bins --no-run-tests --no-run-benchmarks -j2 --ghc-options=-j2 --ghc-options=-O2 --ghc-options="+RTS -M3G -RTS" +RTS -N1 -RTS
