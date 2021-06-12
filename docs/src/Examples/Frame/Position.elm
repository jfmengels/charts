module Examples.Frame.Position exposing (..)


-- THIS IS A GENERATED MODULE!

import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.yAxis [ CA.pinned .max ]
    , C.yTicks [ CA.pinned .max, CA.flip ]
    , C.yLabels [ CA.pinned .max, CA.flip ]
    ]


meta =
  { category = "Frame and navigation"
  , name = "Position"
  , description = "Change color of position."
  , order = 3
  }


type alias Model =
  ()


init : Model
init =
  ()


type Msg
  = Msg


update : Msg -> Model -> Model
update msg model =
  model



smallCode : String
smallCode =
  """
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.yAxis [ CA.pinned .max ]
    , C.yTicks [ CA.pinned .max, CA.flip ]
    , C.yLabels [ CA.pinned .max, CA.flip ]
    ]
  """


largeCode : String
largeCode =
  """
import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.yAxis [ CA.pinned .max ]
    , C.yTicks [ CA.pinned .max, CA.flip ]
    , C.yLabels [ CA.pinned .max, CA.flip ]
    ]
  """