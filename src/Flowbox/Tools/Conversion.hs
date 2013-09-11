---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

{-# LANGUAGE FunctionalDependencies, MultiParamTypeClasses #-}

module Flowbox.Tools.Conversion where

import           Data.Int   


class Convert a b | a -> b, b -> a where
  encode :: a -> b
  decode :: b -> Either String a 


i32toi :: Int32 -> Int
i32toi = fromIntegral


itoi32 :: Int -> Int32
itoi32 = fromIntegral
