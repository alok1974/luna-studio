---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------
module Flowbox.Parser.Handler.Parser where

import Data.IORef (IORef)

import           Flowbox.Batch.Batch                                (Batch)
import qualified Flowbox.Batch.Handler.Parser                       as BatchP
import           Flowbox.Luna.Tools.Serialize.Proto.Conversion.Expr ()
import           Flowbox.Luna.Tools.Serialize.Proto.Conversion.Pat  ()
import           Flowbox.Prelude
import           Flowbox.System.Log.Logger
import           Flowbox.Tools.Serialize.Proto.Conversion.Basic
import qualified Generated.Proto.Parser.Parse.Expr.Request        as ParseExpr
import qualified Generated.Proto.Parser.Parse.Expr.Status      as ParseExpr
import qualified Generated.Proto.Parser.Parse.NodeExpr.Request    as ParseNodeExpr
import qualified Generated.Proto.Parser.Parse.NodeExpr.Status  as ParseNodeExpr
import qualified Generated.Proto.Parser.Parse.Pat.Request         as ParsePat
import qualified Generated.Proto.Parser.Parse.Pat.Status       as ParsePat
import qualified Generated.Proto.Parser.Parse.Type.Request        as ParseType
import qualified Generated.Proto.Parser.Parse.Type.Status      as ParseType



loggerIO :: LoggerIO
loggerIO = getLoggerIO "Flowbox.Batch.Server.Handlers.Parser"

-------- public api -------------------------------------------------

parseExpr :: ParseExpr.Request -> IO ParseExpr.Status
parseExpr (ParseExpr.Request tstr) = do
    loggerIO info "called parseExpr"
    let str = decodeP tstr
    expr <- BatchP.parseExpr str
    return $ ParseExpr.Status $ encode expr


parsePat :: ParsePat.Request -> IO ParsePat.Status
parsePat (ParsePat.Request tstr) = do
    loggerIO info "called parsePat"
    let str = decodeP tstr
    pat <- BatchP.parsePat str
    return $ ParsePat.Status $ encode pat


parseType :: ParseType.Request -> IO ParseType.Status
parseType (ParseType.Request tstr) = do
    loggerIO info "called parseType"
    let str = decodeP tstr
    pat <- BatchP.parseType str
    return $ ParseType.Status $ encode pat


parseNodeExpr :: ParseNodeExpr.Request -> IO ParseNodeExpr.Status
parseNodeExpr (ParseNodeExpr.Request tstr) = do
    loggerIO info "called parseExpr"
    let str = decodeP tstr
    expr <- BatchP.parseNodeExpr str
    return $ ParseNodeExpr.Status $ encode expr
