module Examples.BarCharts.BarLabels exposing (..)


-- THIS IS A GENERATED MODULE!

import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels []
    , C.bars []
        [ C.bar .q []
        , C.bar .p []
        ]
        data

    , C.eachBar <| \p bar ->
        [ C.label
            [ CA.yOff 15, CA.color "white" ]
            [ S.text (String.fromFloat (CE.getDependent bar)) ]
            (CE.getTop p bar)
        ]
    ]


meta =
  { category = "Bar charts"
  , categoryOrder = 1
  , name = "Labels for bars"
  , description = "Add custom bar labels."
  , order = 15
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


type alias Datum =
  { x : Float
  , x1 : Float
  , y : Float
  , z : Float
  , v : Float
  , w : Float
  , p : Float
  , q : Float
  , label : String
  }


data : List Datum
data =
  [ Datum 0.0 0.0 1.2 4.0 4.6 6.9 7.3 8.0 "Norway"
  , Datum 2.0 0.4 2.2 4.2 5.3 5.7 6.2 7.8 "Denmark"
  , Datum 3.0 0.6 1.0 3.2 4.8 5.4 7.2 8.3 "Sweden"
  , Datum 4.0 0.2 1.2 3.0 4.1 5.5 7.9 8.1 "Finland"
  ]



smallCode : String
smallCode =
  """
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels []
    , C.bars []
        [ C.bar .q []
        , C.bar .p []
        ]
        data

    , C.eachBar <| \\p bar ->
        [ C.label
            [ CA.yOff 15, CA.color "white" ]
            [ S.text (String.fromFloat (CE.getDependent bar)) ]
            (CE.getTop p bar)
        ]
    ]
  """


largeCode : String
largeCode =
  """
import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels []
    , C.bars []
        [ C.bar .q []
        , C.bar .p []
        ]
        data

    , C.eachBar <| \\p bar ->
        [ C.label
            [ CA.yOff 15, CA.color "white" ]
            [ S.text (String.fromFloat (CE.getDependent bar)) ]
            (CE.getTop p bar)
        ]
    ]
  """