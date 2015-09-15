module Reactive.Plugins.Core.Action.MultiSelection where

import           Utils.PreludePlus
import           Utils.Vector

import qualified JS.Bindings    as UI
import qualified JS.NodeGraph   as UI
import qualified JS.Camera      as Camera

import           Object.Object
import           Object.Node
import           Object.UITypes

import           Event.Keyboard hiding      (Event)
import qualified Event.Keyboard as Keyboard
import           Event.Mouse    hiding      (Event, WithObjects)
import qualified Event.Mouse    as Mouse
import           Event.Event
import           Event.WithObjects

import           Reactive.Plugins.Core.Action
import           Reactive.Plugins.Core.Action.State.MultiSelection
import           Reactive.Plugins.Core.Action.State.UnderCursor
import qualified Reactive.Plugins.Core.Action.State.Graph          as Graph
import qualified Reactive.Plugins.Core.Action.State.Selection      as Selection
import qualified Reactive.Plugins.Core.Action.State.Camera         as Camera
import qualified Reactive.Plugins.Core.Action.State.Global         as Global

data DragType = StartDrag
              | Moving
              | Dragging
              | StopDrag
              deriving (Eq, Show)


data Action = DragSelect { _actionType    :: DragType
                         , _startPos      :: Vector2 Int
                         }
              deriving (Eq, Show)

makeLenses ''Action


instance PrettyPrinter DragType where
    display = show

instance PrettyPrinter Action where
    display (DragSelect tpe point) = "msA(" <> display tpe <> " " <> display point <> ")"


toAction :: Event Node -> Global.State -> UnderCursor -> Maybe Action
toAction (Mouse (Mouse.Event tpe pos button keyMods evWdgt)) state underCursor = case button of
    LeftButton   -> case tpe of
        Mouse.Pressed  -> if dragAllowed then case keyMods of
                                             (KeyMods False False False False) -> Just (DragSelect StartDrag pos)
                                             _                                 -> Nothing
                                         else Nothing
                        where   -- TODO: switch to our RayCaster
                            portMay       = getPortRefUnderCursor state
                            dragAllowed   = (null $ underCursor ^. nodesUnderCursor) && (isNothing portMay) && (isNothing evWdgt)
        Mouse.Released -> Just (DragSelect StopDrag pos)
        Mouse.Moved    -> Just (DragSelect Moving pos)
        _              -> Nothing
    _                  -> Nothing
toAction _ _  _         = Nothing


instance ActionStateUpdater Action where
    execSt newActionCandidate oldState = case newAction of
        Just action -> ActionUI newAction newState
        Nothing     -> ActionUI  NoAction newState
        where
        oldDrag                          = oldState ^. Global.multiSelection . history
        oldGraph                         = oldState ^. Global.graph
        oldNodes                         = Graph.getNodes oldGraph
        newGraph                         = Graph.selectNodes newNodeIds oldGraph
        oldSelection                     = oldState ^. Global.selection . Selection.nodeIds
        newState                         = oldState & Global.iteration                     +~ 1
                                                    & Global.multiSelection . history      .~ newDrag
                                                    & Global.selection . Selection.nodeIds .~ newNodeIds
                                                    & Global.graph                         .~ newGraph
        newAction                        = case newActionCandidate of
            DragSelect Moving pt        -> case oldDrag of
                Nothing                 -> Nothing
                _                       -> Just $ DragSelect Dragging pt
            _                           -> Just newActionCandidate
        newNodeIds                       = case newActionCandidate of
            DragSelect tpe point        -> case tpe of
                Moving                  -> case oldDrag of
                    Just oldDragState   -> getNodeIdsIn startPos point (Global.toCamera oldState) oldNodes
                        where startPos   = oldDragState ^. dragStartPos
                    Nothing             -> oldSelection
                _                       -> oldSelection
        newDrag                          = case newActionCandidate of
            DragSelect tpe point        -> case tpe of
                StartDrag               -> Just $ DragHistory point point
                Moving                  -> case oldDrag of
                    Just oldDragState   -> Just $ DragHistory startPos point
                        where startPos   = oldDragState ^. dragStartPos
                    Nothing             -> Nothing
                StopDrag                -> Nothing


instance ActionUIUpdater Action where
    updateUI (WithState action state) = case action of
        DragSelect Dragging _  -> do
                                  UI.displaySelectionBox startSelectionBox endSelectionBox
                                  UI.unselectNodes unselectedNodeIds
                                  UI.selectNodes     selectedNodeIds
                                  mapM_ UI.setNodeFocused topNodeId
        DragSelect StopDrag _  -> UI.hideSelectionBox
        _                      -> return ()
        where selectedNodeIds   = state ^. Global.selection . Selection.nodeIds
              nodeList          = Graph.getNodes $ state ^. Global.graph
              unselectedNodeIds = filter (\nodeId -> not $ nodeId `elem` selectedNodeIds) $ (^. nodeId) <$> nodeList
              topNodeId         = selectedNodeIds ^? ix 0
              dragState         = fromJust (state ^. Global.multiSelection . history)
              camera            = Global.toCamera state
              currWorkspace     = Camera.screenToWorkspace camera
              startSelectionBox = currWorkspace $ dragState ^. dragStartPos
              endSelectionBox   = currWorkspace $ dragState ^. dragCurrentPos
