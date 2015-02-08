-- extensions --
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE RebindableSyntax #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE CPP #-}
{-# LANGUAGE DysfunctionalDependencies #-}
{-# LANGUAGE ExtendedDefaultRules #-}

-- module --
module Main where

-- imports --
import Luna.Target.HS

-- body --
#include "pragmas.cpp"

-- ====== Main type ====== --
data Main  = Main deriving (Show, Eq, Ord, Generic, Typeable)
data Cls_Main  = Cls_Main deriving (Show, Eq, Ord, Generic, Typeable)

-- ------ Main.Main constructor ------ --
cons_Main = _member("Main") (val Cls_Main)
memDef_Cls_Main_Main = liftCons0 Main

-- ====== Method: Cls_Main.Main ====== --
memSig_Cls_Main_Main = _rtup1(_nuSigArg("self"))
memFnc_Cls_Main_Main = (memSig_Cls_Main_Main, memDef_Cls_Main_Main)
$(registerMethod ''Cls_Main "Main")

-- ------ Main methods ------ --

-- ====== Method: Main.print ====== --
memSig_Main_print = _rtup2(_nuSigArg("self"), _npSigArg("s", val ("" :: String)))
memDef_Main_print self s = do 
     
    polyJoin . liftF1 (Value . fmap Safe . print) $ s
     

memFnc_Main_print = (memSig_Main_print, memDef_Main_print)
$(registerMethod ''Main "print")

-- ====== Vector type ====== --
data Vector a = Vector a a a deriving (Show, Eq, Ord, Generic, Typeable)
data Cls_Vector  = Cls_Vector deriving (Show, Eq, Ord, Generic, Typeable)

-- ------ Vector.Vector constructor ------ --
cons_Vector = _member("Vector") (val Cls_Vector)
memDef_Cls_Vector_Vector = liftCons3 Vector

-- ====== Method: Cls_Vector.Vector ====== --
memSig_Cls_Vector_Vector = _rtup4(_nuSigArg("self"), _nuSigArg("x"), _nuSigArg("y"), _nuSigArg("z"))
memFnc_Cls_Vector_Vector = (memSig_Cls_Vector_Vector, memDef_Cls_Vector_Vector)
$(registerMethod ''Cls_Vector "Vector")

-- ------ Vector accessors ------ --
$(generateFieldAccessors ''Vector [('Vector, [Just "x", Just "y", Just "z"])])
$(registerFieldAccessors ''Vector ["x", "y", "z"])

-- ------ Vector methods ------ --

-- ====== Method: Main.test ====== --
memSig_Main_test = _rtup2(_nuSigArg("self"), _nuSigArg("x"))
memDef_Main_test _self _x = do 
     _x
     

memFnc_Main_test = (memSig_Main_test, memDef_Main_test)
$(registerMethod ''Main "test")

-- ====== Method: Main.main ====== --
memSig_Main_main = _rtup1(_nuSigArg("self"))

-- ====== Method: Main.lambda__49 ====== --
memSig_Main_lambda__49 = _rtup2(_nuSigArg("self"), _nuSigArg("x"))
memDef_Main_lambda__49 _self _x = do 
     val (_x, _x)
     

memFnc_Main_lambda__49 = (memSig_Main_lambda__49, memDef_Main_lambda__49)
$(registerMethod ''Main "lambda__49")
memDef_Main_main _self = do 
     _v <- _call(0) (appNext (val (3 :: Int)) (appNext (val (2 :: Int)) (appByName _name("y") (val (1 :: Int)) cons_Vector)))
     _foo <- _member("lambda__49") (_call(2) cons_Main)
     _bar <- _member("test") _self
     _call(3) (appNext (_call(4) (appNext (val (1 :: Int)) _foo)) (_member("print") _self))
     _call(5) (appNext _v (_member("print") _self))
     

memFnc_Main_main = (memSig_Main_main, memDef_Main_main)
$(registerMethod ''Main "main")


-- ===================================================================
-- Main module wrappers
-- ===================================================================
main = mainMaker cons_Main

