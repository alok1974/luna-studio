module Reactive.Commands.Graph.Render
    ( renderGraph
    ) where

import           Utils.PreludePlus

import qualified Data.Map.Lazy                   as Map

import           Empire.API.Data.Node            (Node)
import qualified Empire.API.Data.Node            as Node
import           Empire.API.Data.PortRef         (InPortRef, OutPortRef)

import           Reactive.Commands.Command       (Command)
import           Reactive.Commands.Graph         (updateConnections)
import           Reactive.Commands.Graph.Connect (localConnectNodes)
import           Reactive.Commands.Node.Create   (registerNode)
import           Reactive.State.Global           (State)
import qualified Reactive.State.Global           as Global
import qualified Reactive.State.Graph            as Graph

fastAddNodes :: [Node] -> Command State ()
fastAddNodes nodes = do
    let nodeIds = (view Node.nodeId) <$> nodes
    Global.graph . Graph.nodesMap .= (Map.fromList $ nodeIds `zip` nodes)
    forM_ nodes $ \node -> registerNode node

renderGraph :: [Node] -> [(OutPortRef, InPortRef)] -> Command State ()
renderGraph nodes edges = do
    fastAddNodes nodes
    mapM_ (uncurry localConnectNodes) edges
    updateConnections