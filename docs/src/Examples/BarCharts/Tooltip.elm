module Examples.BarCharts.Tooltip exposing (..)


-- THIS IS A GENERATED MODULE!

import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE


type alias Model =
  { hovering : List (CE.Product CE.Bar (Maybe Float) Datum) }


init : Model
init =
  { hovering = [] }


type Msg
  = OnHover (List (CE.Product CE.Bar (Maybe Float) Datum))


update : Msg -> Model -> Model
update msg model =
  case msg of
    OnHover hovering ->
      { model | hovering = hovering }


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    , CE.onMouseMove OnHover (CE.getNearest CE.bar)
    , CE.onMouseLeave (OnHover [])
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels []
    , C.bars []
        [ C.stacked
            [ C.bar .z []
            , C.bar .y []
            ]
        , C.bar .v [ CA.color CA.turquoise ]
        ]
        data
    , C.each model.hovering <| \p item ->
        [ C.tooltip item [ CA.onTop ] [] [] ]
    ]


meta =
  { category = "Bar charts"
  , categoryOrder = 1
  , name = "Tooltip"
  , description = "Add a basic tooltip for nearest bar."
  , order = 12
  }



type alias Datum =
  { x : Float
  , x1 : Float
  , x2 : Float
  , y : Maybe Float
  , z : Maybe Float
  , v : Maybe Float
  , w : Maybe Float
  , p : Maybe Float
  , q : Maybe Float
  }


data : List Datum
data =
  let toDatum x x1 y z v w p q =
        Datum x x1 x1 (Just y) (Just z) (Just v) (Just w) (Just p) (Just q)
  in
  [ toDatum 0.0 0.0 1.2 4.0 4.6 6.9 7.3 8.0
  , toDatum 2.0 0.4 2.2 4.2 5.3 5.7 6.2 7.8
  , toDatum 3.0 0.6 1.0 3.2 4.8 5.4 7.2 8.3
  , toDatum 4.0 0.2 1.2 3.0 4.1 5.5 7.9 8.1
  ]



smallCode : String
smallCode =
  """
  C.chart
    [ CA.height 300
    , CA.width 300
    , CE.onMouseMove OnHover (CE.getNearest CE.bar)
    , CE.onMouseLeave (OnHover [])
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels []
    , C.bars []
        [ C.stacked
            [ C.bar .z []
            , C.bar .y []
            ]
        , C.bar .v [ CA.color CA.turquoise ]
        ]
        data
    , C.each model.hovering <| \\p item ->
        [ C.tooltip item [ CA.onTop ] [] [] ]
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


type alias Model =
  { hovering : List (CE.Product CE.Bar (Maybe Float) Datum) }


init : Model
init =
  { hovering = [] }


type Msg
  = OnHover (List (CE.Product CE.Bar (Maybe Float) Datum))


update : Msg -> Model -> Model
update msg model =
  case msg of
    OnHover hovering ->
      { model | hovering = hovering }


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    , CE.onMouseMove OnHover (CE.getNearest CE.bar)
    , CE.onMouseLeave (OnHover [])
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels []
    , C.bars []
        [ C.stacked
            [ C.bar .z []
            , C.bar .y []
            ]
        , C.bar .v [ CA.color CA.turquoise ]
        ]
        data
    , C.each model.hovering <| \\p item ->
        [ C.tooltip item [ CA.onTop ] [] [] ]
    ]
  """