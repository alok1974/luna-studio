module Object.Widget.Number.Discrete where

import Utils.PreludePlus
import Utils.Vector
import Data.Fixed
import Object.Widget
import Numeric
import Data.Aeson (ToJSON)

data DiscreteNumber = DiscreteNumber { _position       :: Vector2 Double
                                     , _size           :: Vector2 Double
                                     , _label          :: Text
                                     , _value          :: Int
                                     , _enabled        :: Bool
                                     , _dragStartValue :: Maybe Int
                                     } deriving (Eq, Show, Typeable, Generic)

makeLenses ''DiscreteNumber
instance ToJSON DiscreteNumber

create :: Size -> Text -> Int -> DiscreteNumber
create s l v = DiscreteNumber def s l v True def

instance IsDisplayObject DiscreteNumber where
    widgetPosition = position
    widgetSize     = size

displayValue' :: DiscreteNumber -> String
displayValue' model = show $ model ^. value

displayValue :: Getter DiscreteNumber String
displayValue = to displayValue'