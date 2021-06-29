module Examples.Interactivity.FilterSearch exposing (..)

{-| @LARGE -}
import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE


type alias Model =
  { hovering : List (CE.Group (CE.Stack Datum) CE.Dot (Maybe Float) Datum) }


init : Model
init =
  { hovering = [] }


type Msg
  = OnHover (List (CE.Group (CE.Stack Datum) CE.Dot (Maybe Float) Datum))


update : Msg -> Model -> Model
update msg model =
  case msg of
    OnHover hovering ->
      { model | hovering = hovering }


view : Model -> H.Html Msg
view model =
{-| @SMALL -}
  C.chart
    [ CA.height 300
    , CA.width 300
    , CA.paddingLeft 10
    , CE.dot
        |> CE.collect CE.stack
        |> CE.getNearest
        |> CE.onMouseMove OnHover
    , CE.onMouseLeave (OnHover [])
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels [ CA.pinned .min ]
    , C.series .x
        [ C.stacked
          [ C.interpolated .p [  ] [ CA.circle ]
          , C.interpolated .q [  ] [ CA.circle ]
          ]
        ]
        data
    , C.bars [ CA.x1 .x1, CA.x2 .x2 ]
        [ C.bar .z [ CA.color CA.purple ]
        ]
        data
    , C.each model.hovering <| \p item ->
        [ C.tooltip item [] [] [] ]
    ]
{-| @SMALL END -}
{-| @LARGE END -}


meta =
  { category = "Interactivity"
  , categoryOrder = 5
  , name = "Filter item search"
  , description = "Narrow down tooltip item search."
  , order = 15
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
        Datum x x1 (x1 + 1) (Just y) (Just z) (Just v) (Just w) (Just p) (Just q)
  in
  [ toDatum 0.0 0.0 1.2 4.0 4.6 6.9 7.3 8.0
  , toDatum 2.0 1.0 2.2 4.2 5.3 5.7 6.2 7.8
  , toDatum 3.0 2.0 1.0 3.2 4.8 5.4 7.2 8.3
  , toDatum 4.0 3.0 1.2 3.0 4.1 5.5 7.9 8.1
  ]

