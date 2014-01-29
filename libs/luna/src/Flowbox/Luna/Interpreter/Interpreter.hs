---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------


module Flowbox.Luna.Interpreter.Interpreter where

import           Control.Concurrent.Chan (Chan)
import qualified Control.Concurrent.Chan as Chan
import           Control.Monad           (forever)
import           DynFlags                (PkgConfRef (PkgConfFile))
import qualified DynFlags                as F
import           GHC                     (Ghc, GhcMonad)
import qualified GHC                     as GHC
import           MonadUtils              (liftIO)

import           Flowbox.Config.Config (Config)
import qualified Flowbox.Config.Config as Config
import           Flowbox.Prelude


initialize :: GhcMonad m => Config -> m ()
initialize config = do
    flags <- GHC.getSessionDynFlags
    _ <- GHC.setSessionDynFlags flags
                { GHC.extraPkgConfs = ( [ PkgConfFile $ Config.pkgDb $ Config.global config
                                        , PkgConfFile $ Config.pkgDb $ Config.local config
                                        ] ++) . GHC.extraPkgConfs flags
                , GHC.hscTarget = GHC.HscInterpreted
                , GHC.ghcLink   = GHC.LinkInMemory
                --, GHC.verbosity = 4
                }
    return ()


run :: Config -> Ghc a -> IO a
run config r = GHC.runGhc (Just $ Config.topDir $ Config.ghcS config) r


setHardodedExtensions :: GhcMonad m => m ()
setHardodedExtensions = do
    flags <- GHC.getSessionDynFlags
    let f = foldl F.xopt_set flags [ F.Opt_TemplateHaskell,
                                     F.Opt_DataKinds,
                                     F.Opt_DeriveDataTypeable,
                                     F.Opt_DeriveGeneric,
                                     F.Opt_FlexibleInstances,
                                     F.Opt_MultiParamTypeClasses,
                                     F.Opt_RebindableSyntax,
                                     F.Opt_ScopedTypeVariables,
                                     F.Opt_TemplateHaskell,
                                     F.Opt_UndecidableInstances]
        f' = foldl F.xopt_unset f  [ F.Opt_MonomorphismRestriction]
    _ <- GHC.setSessionDynFlags f'
    return ()


setImports :: GhcMonad m => [String] -> m ()
setImports = GHC.setContext . map (GHC.IIDecl . GHC.simpleImportDecl . GHC.mkModuleName)


channelLoop :: GhcMonad m => Chan String -> [String] -> m ()
channelLoop chan imports = forever $ do
    code <- liftIO $ Chan.readChan chan

    GHC.setTargets []
    GHC.load GHC.LoadAllTargets

    setImports imports

    _ <- GHC.runDecls code
    _ <- GHC.runStmt "main" GHC.RunToCompletion
    return ()


runChannelLoop :: Config -> Chan String -> [String] -> IO ()
runChannelLoop config chan imports = run config $ channelLoop chan imports

