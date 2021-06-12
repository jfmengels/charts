module Examples.Frame.NoArrow exposing (..)


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
    , C.xAxis [ CA.noArrow ]
    , C.xTicks []
    , C.xLabels []
    ]


meta =
  { category = "Frame and navigation"
  , name = "Remove arrow"
  , description = "Remove arrow from axis line."
  , order = 5
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
    , C.xAxis [ CA.noArrow ]
    , C.xTicks []
    , C.xLabels []
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
    , C.xAxis [ CA.noArrow ]
    , C.xTicks []
    , C.xLabels []
    ]
  """