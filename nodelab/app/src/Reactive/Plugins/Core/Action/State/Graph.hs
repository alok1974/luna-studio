module Reactive.Plugins.Core.Action.State.Graph where


import           Utils.PreludePlus
import           Utils.Vector

import           Data.IntMap.Lazy (IntMap)
import qualified Data.IntMap.Lazy as IntMap

import           Object.Object
import           Object.Port
import           Object.Node

import           Luna.Syntax.Builder.Graph hiding (get, put)
import           Luna.Syntax.Builder
import           AST.AST


type NodesMap = IntMap Meta


data State = State { _nodeList  :: NodeCollection
                   , _nodes     :: NodesMap
                   , _bldrState :: BldrState GraphMeta
                   } deriving (Show)

makeLenses ''State


-- instance Show State where
--     show a = show $ IntMap.size $ a ^. nodes

instance Eq State where
    a == b = (a ^. nodeList) == (b ^. nodeList) && (a ^. nodes) == (b ^. nodes)

instance Default State where
    def = State def def def

instance PrettyPrinter State where
    display (State nodesList nodes bldrState) =
           "nM(" <> show nodesList
        <> ", "  <> show (IntMap.keys nodes)
        <> ", "  <> show bldrState
        <> ")"


getNodes :: State -> NodeCollection
getNodes = (^. nodeList)

updateNodes :: NodeCollection -> State -> State
updateNodes newNodeList state = state & nodeList .~ newNodeList