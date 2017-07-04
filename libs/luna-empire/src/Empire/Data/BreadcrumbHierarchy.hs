{-# LANGUAGE GADTs #-}
{-# LANGUAGE UndecidableInstances #-}

module Empire.Data.BreadcrumbHierarchy where

import           Prologue                   hiding (children)

import           LunaStudio.Data.Breadcrumb (Breadcrumb (..), BreadcrumbItem (..))
import           LunaStudio.Data.Node       (NodeId)

import           Empire.Data.AST            (NodeRef)

import           Data.Map                   (Map)
import qualified Data.Map                   as Map


data LamItem = LamItem { _portMapping :: (NodeId, NodeId)
                       , _lamRef      :: NodeRef
                       , _lamChildren :: Map NodeId BChild
                       , _lamBody     :: NodeRef
                       } deriving (Show, Eq)

data ExprItem = ExprItem { _portChildren :: Map Int LamItem
                         , _selfRef      :: NodeRef
                         } deriving (Show, Eq)

data TopItem = TopItem { _childNodes :: Map NodeId BChild
                       , _topBody    :: Maybe NodeRef
                       } deriving (Show, Eq)

data BChild  = ExprChild       ExprItem | LambdaChild  LamItem deriving (Show, Eq)
data BParent = ToplevelParent  TopItem  | LambdaParent LamItem deriving (Show, Eq)

makeLenses ''LamItem
makeLenses ''ExprItem
makeLenses ''TopItem
makePrisms ''BChild
makePrisms ''BParent

instance Default TopItem where
    def = TopItem def def

instance Default BParent where
    def = ToplevelParent def

class HasSelf a where
    self :: Lens' a NodeRef

instance HasSelf LamItem where
    self = lamRef

instance HasSelf ExprItem where
    self = selfRef

instance HasSelf BChild where
    self = lens get set where
        get (ExprChild   a)   = a ^. self
        get (LambdaChild a)   = a ^. self
        set (ExprChild   a) s = ExprChild   $ a & self .~ s
        set (LambdaChild a) s = LambdaChild $ a & self .~ s

class HasChildren a where
    children :: Lens' a (Map NodeId BChild)

instance HasChildren LamItem where
    children = lamChildren

instance HasChildren TopItem where
    children = childNodes

instance HasChildren BParent where
    children = lens get set where
        get (ToplevelParent i) = i ^. children
        get (LambdaParent   i) = i ^. children
        set (ToplevelParent i) c = ToplevelParent $ i & children .~ c
        set (LambdaParent   i) c = LambdaParent   $ i & children .~ c

class HasBody a where
    body :: Traversal' a NodeRef

instance HasBody LamItem where
    body = lamBody

instance HasBody TopItem where
    body = topBody . _Just

instance HasBody BParent where
    body trans s = case s of
        LambdaParent   i -> LambdaParent   <$> body trans i
        ToplevelParent i -> ToplevelParent <$> body trans i

class HasRefs a where
    refs :: Traversal' a NodeRef

instance HasRefs NodeRef where
    refs = id

instance {-# OVERLAPPABLE #-} (Traversable t, HasRefs a) => HasRefs (t a) where
    refs = traverse . refs

instance HasRefs TopItem where
    refs f (TopItem children top) = TopItem <$> refs f children <*> refs f top

instance HasRefs LamItem where
    refs f (LamItem pm ref children body) = LamItem pm <$> refs f ref <*> refs f children <*> refs f body

instance HasRefs ExprItem where
    refs f (ExprItem children ref) = ExprItem <$> refs f children <*> refs f ref

instance HasRefs BChild where
    refs f (ExprChild   it) = ExprChild   <$> refs f it
    refs f (LambdaChild it) = LambdaChild <$> refs f it

instance HasRefs BParent where
    refs f (ToplevelParent it) = ToplevelParent <$> refs f it
    refs f (LambdaParent   it) = LambdaParent   <$> refs f it

class DescedantTraversable a where
    traverseDescedants :: Traversal' a BChild

instance {-# OVERLAPPABLE #-} HasChildren a => DescedantTraversable a where
    traverseDescedants = children . traverse . traverseDescedants

instance DescedantTraversable ExprItem where
    traverseDescedants = portChildren . traverse . traverseDescedants

instance DescedantTraversable BChild where
    traverseDescedants f (ExprChild   it) = ExprChild   <$> traverseDescedants f it
    traverseDescedants f (LambdaChild it) = LambdaChild <$> traverseDescedants f it

getBreadcrumbItems :: BParent -> Breadcrumb BreadcrumbItem -> [BChild]
getBreadcrumbItems b (Breadcrumb crumbs) = go crumbs b where
    go [] _ = []
    go (Lambda id : crumbs) b = case b ^? children . ix id of
        Just (LambdaChild c) -> LambdaChild c : go crumbs (LambdaParent c)
        Just (ExprChild   c) -> ExprChild   c : []
        Nothing              -> []

navigateTo :: BParent -> Breadcrumb BreadcrumbItem -> Maybe BParent
navigateTo b (Breadcrumb crumbs) = go crumbs b where
    go [] b = pure b
    go (Lambda id : crumbs) b = do
        child <- b ^? children . ix id . _LambdaChild . re _LambdaParent
        go crumbs child
    go (Arg id pos : crumbs) b = do
        child <- b ^? children . ix id . _ExprChild . portChildren . ix pos . re _LambdaParent
        go crumbs child

replaceAt :: Breadcrumb BreadcrumbItem -> BParent -> BParent -> Maybe BParent
replaceAt (Breadcrumb crumbs) par child = go crumbs par child where
    go [] par child = pure child
    go (Lambda id : crumbs) par child = do
        lowerPar <- par ^? children . ix id . _LambdaChild . re _LambdaParent
        LambdaParent replaced <- go crumbs lowerPar child
        return $ par & children . ix id . _LambdaChild .~ replaced
    go (Arg id pos : crumbs) par child = do
        lowerPar <- par ^? children . ix id . _ExprChild . portChildren . ix pos . re _LambdaParent
        LambdaParent replaced <- go crumbs lowerPar child
        return $ par & children . ix id . _ExprChild . portChildren . ix pos .~ replaced

topLevelIDs :: BParent -> [NodeId]
topLevelIDs = Map.keys . view children

getLamItems :: BParent -> [((NodeId, Maybe Int), LamItem)]
getLamItems hierarchy = goParent hierarchy
    where
        goParent (ToplevelParent topItem) = goTopItem topItem
        goParent (LambdaParent   lamItem) = $notImplemented

        goBChild nodeId (ExprChild exprItem)  = goExprItem nodeId exprItem
        goBChild nodeId (LambdaChild lamItem) = goLamItem (nodeId, Nothing) lamItem

        goTopItem (TopItem childNodes _) = concatMap (\(a,b) -> goBChild a b) $ Map.assocs childNodes

        goLamItem idArg lamItem = (idArg, lamItem) : concatMap (\(a, b) -> goBChild a b) (Map.assocs $ lamItem ^. children)

        goExprItem nodeId (ExprItem children _) = map (\(a,b) -> ((nodeId, Just a), b)) $ Map.assocs children