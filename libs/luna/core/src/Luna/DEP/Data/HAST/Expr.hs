---------------------------------------------------------------------------
-- Copyright (C) Flowbox, Inc - All Rights Reserved
-- Unauthorized copying of this file, via any medium is strictly prohibited
-- Proprietary and confidential
-- Flowbox Team <contact@flowbox.io>, 2014
---------------------------------------------------------------------------

module Luna.DEP.Data.HAST.Expr where

import           Flowbox.Prelude
import           Luna.DEP.Data.HAST.Comment   (Comment)
import           Luna.DEP.Data.HAST.Deriving  (Deriving)
import           Luna.DEP.Data.HAST.Extension (Extension)
import qualified Luna.DEP.Data.HAST.Lit       as Lit

type Lit = Lit.Lit

data Expr = Assignment { src       :: Expr     , dst       :: Expr                                }
          | Arrow      { src       :: Expr     , dst       :: Expr                                }
          | Tuple      { items :: [Expr]                                                          }
          | TupleP     { items :: [Expr]                                                          }
          | ListE      { items :: [Expr]                                                          }
          | ListT      { item :: Expr                                                            }
          | StringLit  { litval :: String                                                         }
          | Var        { name :: String                                                           }
          | VarE       { name :: String                                                           }
          | VarT       { name :: String                                                           }
          | LitT       { lval :: Lit                                                              }
          | Typed      { cls       :: Expr     , expr      :: Expr                                }
          | TypedP     { cls       :: Expr     , expr      :: Expr                                }
          | TypedE     { cls       :: Expr     , expr      :: Expr                                }
          | TySynD     { name      :: String   , paramsE   :: [Expr]      , dstType   :: Expr     } -- FIXME: paramsE -> params
          | Function   { name      :: String   , pats      :: [Expr]      , expr      :: Expr     }
          | Lambda     { paths     :: [Expr]   , expr      :: Expr                                }
          | LetBlock   { exprs     :: [Expr]   , result    :: Expr                                }
          | LetExpr    { expr :: Expr                                                        }
          | DoBlock    { exprs :: [Expr]                                                          }
          | DataD      { name      :: String   , params    :: [String]    , cons      :: [Expr] , derivings :: [Deriving]   }
          | NewTypeD   { name      :: String   , paramsE   :: [Expr]      , con       :: Expr     } -- FIXME: paramsE -> params
          | InstanceD  { tp        :: Expr     , decs      :: [Expr]                              }
          | Con        { name      :: String   , fields    :: [Expr]                              }
          | ConE       { qname :: [String]                                                        }
          | ConT       { name :: String                                                           }
          | ConP       { name :: String                                                           }
          | CondE      { cond :: Expr , success :: [Expr], failure :: [Expr]                      }
          | RecUpdE    { expr :: Expr , name :: String, val :: Expr}
          -- | Module     { path      :: [String] , ext       :: [Extension] , imports   :: [Expr]   , newtypes  :: [Expr]       , datatypes :: [Expr]  , methods :: [Expr] , thexpressions :: [Expr] }
          | Module     { path      :: [String] , ext       :: [Extension] , imports   :: [Expr]   , body  :: [Expr]}
          | Import     { qualified :: Bool     , segments  :: [String]    , rename    :: Maybe String                           }
          | ImportNative { code :: String                                                      }
          | AppE       { src       :: Expr     , dst       :: Expr                                }
          | AppT       { src       :: Expr     , dst       :: Expr                                }
          | AppP       { src       :: Expr     , dst       :: Expr                                }
          | Infix      { name      :: String   , src       :: Expr        , dst          :: Expr  }
          | Lit        { lval :: Lit                                                              }
          | Native     { code :: String                                                           }
          | THE        { expr :: Expr                                                             }
          | CaseE      { expr :: Expr, matches :: [Expr]                                          }
          | Match      { pat :: Expr, matchBody :: Expr }
          | Comment    { comment :: Comment }
          | ViewP      { name :: String, dst :: Expr}
          | WildP
          | RecWildP
          | NOP
          | Undefined
          | Bang Expr
          deriving (Show)

