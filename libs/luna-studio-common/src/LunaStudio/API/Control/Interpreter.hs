module LunaStudio.API.Control.Interpreter where

import           Data.Aeson.Types        (ToJSON)
import           Data.Binary             (Binary)
import qualified LunaStudio.API.Graph.Request  as G
import qualified LunaStudio.API.Request  as R
import qualified LunaStudio.API.Response as Response
import qualified LunaStudio.API.Topic    as T
import qualified LunaStudio.API.Topic    as T
import           LunaStudio.Data.GraphLocation (GraphLocation)
import           Prologue


data Request = Start { _location :: GraphLocation }
             | Pause { _location :: GraphLocation }
             | Reload { _location :: GraphLocation }
             deriving (Eq, Generic, Show)

data Update = Update Text deriving (Eq, Generic, Show)

makeLenses ''Request
makeLenses ''Update
instance Binary Request
instance NFData Request
instance ToJSON Request
instance Binary Update
instance NFData Update
instance ToJSON Update

instance G.GraphRequest Request where location = location

type Response = Response.Response Request () ()
instance Response.ResponseResult Request () ()

topicPrefix :: T.Topic
topicPrefix = "empire.control.interpreter"

instance T.MessageTopic (R.Request Request) where topic _ = topicPrefix <> T.request
instance T.MessageTopic Response            where topic _ = topicPrefix <> T.response
instance T.MessageTopic Update              where topic _ = topicPrefix <> T.update
