module Flowbox'.Core (
    module Flowbox'.TH.Inst,
    module Flowbox'.Core,
    module Flowbox'.Common
)
where

import Flowbox'.TH.Inst
import Flowbox'.Common

(.:) :: (c -> d) -> (a -> b -> c) -> (a -> b -> d)
-- f .: g = \x y->f (g x y)
-- f .: g = (f .) . g
-- (.:) f = ((f .) .)
-- (.:) = (.) (.) (.)
(.:) = (.) . (.)