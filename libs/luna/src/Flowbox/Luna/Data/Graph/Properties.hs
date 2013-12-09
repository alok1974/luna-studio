---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2013
---------------------------------------------------------------------------

module Flowbox.Luna.Data.Graph.Properties where

import           Flowbox.Luna.Data.Attributes  (Attributes)
import qualified Flowbox.Luna.Data.Attributes  as Attributes
import           Flowbox.Luna.Data.Graph.Flags (Flags)
import qualified Flowbox.Luna.Data.Graph.Flags as Flags
import           Flowbox.Prelude



data Properties = Properties { flags :: Flags
                             , attrs :: Attributes
                             } deriving (Show)

empty :: Properties
empty = Properties Flags.empty Attributes.empty
