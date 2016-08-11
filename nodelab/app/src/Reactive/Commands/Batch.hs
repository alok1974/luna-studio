module Reactive.Commands.Batch  where

import           Data.UUID.Types              (UUID)
import           Utils.PreludePlus

import           Batch.Workspace              (Workspace)
import qualified BatchConnector.Commands      as BatchCmd

import           Reactive.Commands.Command    (Command, performIO)
import           Reactive.Commands.UUID       (registerRequest)
import           Reactive.State.Global        (State, workspace, clientId)

import qualified Empire.API.Data.DefaultValue as DefaultValue
import           Empire.API.Data.Node         (NodeId)
import           Empire.API.Data.Project      (ProjectId)
import           Empire.API.Data.NodeMeta     (NodeMeta)
import           Empire.API.Data.PortRef      (AnyPortRef (..), InPortRef (..), OutPortRef (..))
import qualified Empire.API.Data.PortRef      as PortRef (nodeId, dstNodeId)


withWorkspace :: (Workspace -> UUID -> IO ()) -> Command State ()
withWorkspace act = do
    uuid      <- registerRequest
    workspace <- use workspace
    performIO $ act workspace uuid

withWorkspace' :: (Workspace -> IO ()) -> Command State ()
withWorkspace' act = do
    workspace <- use workspace
    performIO $ act workspace

withUUID :: (UUID -> IO ()) -> Command State ()
withUUID act = do
    uuid <- registerRequest
    performIO $ act uuid

addNode :: Text -> NodeMeta -> Maybe NodeId -> Command State ()
addNode = withWorkspace .:. BatchCmd.addNode

createProject :: Text -> Command State ()
createProject = withUUID . BatchCmd.createProject

listProjects ::  Command State ()
listProjects = withUUID BatchCmd.listProjects

createLibrary :: Text -> Text -> Command State ()
createLibrary = withWorkspace .: BatchCmd.createLibrary

listLibraries :: ProjectId -> Command State ()
listLibraries = withUUID . BatchCmd.listLibraries

getProgram :: Command State ()
getProgram = withWorkspace BatchCmd.getProgram

updateNodeMeta :: NodeId -> NodeMeta -> Command State ()
updateNodeMeta = withWorkspace .: BatchCmd.updateNodeMeta

renameNode :: NodeId -> Text -> Command State ()
renameNode = withWorkspace .:  BatchCmd.renameNode

removeNode :: [NodeId] -> Command State ()
removeNode = withWorkspace . BatchCmd.removeNode

connectNodes :: OutPortRef -> InPortRef -> Command State ()
connectNodes src dst = do
    collaborativeModify [dst ^. PortRef.dstNodeId]
    withWorkspace $ BatchCmd.connectNodes src dst

disconnectNodes :: InPortRef -> Command State ()
disconnectNodes dst = do
    collaborativeModify [dst ^. PortRef.dstNodeId]
    withWorkspace $ BatchCmd.disconnectNodes dst

setDefaultValue :: AnyPortRef -> DefaultValue.PortDefault -> Command State ()
setDefaultValue portRef value = do
    collaborativeModify [portRef ^. PortRef.nodeId]
    withWorkspace $ BatchCmd.setDefaultValue portRef value

setInputNodeType :: NodeId -> Text -> Command State ()
setInputNodeType = withWorkspace .: BatchCmd.setInputNodeType

requestCollaborationRefresh :: Command State ()
requestCollaborationRefresh = do
    clId <- use $ clientId
    withWorkspace' $ BatchCmd.requestCollaborationRefresh clId

collaborativeTouch :: [NodeId] -> Command State ()
collaborativeTouch nodeIds = when (length nodeIds > 0) $ do
    clId <- use $ clientId
    withWorkspace' $ BatchCmd.collaborativeTouch clId nodeIds

collaborativeModify :: [NodeId] -> Command State ()
collaborativeModify nodeIds = when (length nodeIds > 0) $ do
    clId <- use $ clientId
    withWorkspace' $ BatchCmd.collaborativeModify clId nodeIds

cancelCollaborativeTouch :: [NodeId] -> Command State ()
cancelCollaborativeTouch nodeIds = when (length nodeIds > 0) $ do
    clId <- use $ clientId
    withWorkspace' $ BatchCmd.cancelCollaborativeTouch clId nodeIds

exportProject :: ProjectId -> Command State ()
exportProject = withUUID . BatchCmd.exportProject

importProject :: Text -> Command State ()
importProject = withUUID . BatchCmd.importProject

dumpGraphViz :: Command State ()
dumpGraphViz = withWorkspace BatchCmd.dumpGraphViz

