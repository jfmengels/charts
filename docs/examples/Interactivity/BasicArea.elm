module Examples.Interactivity.BasicArea exposing (..)

{-| @LARGE -}
import Html as H
import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE


type alias Model =
  { hovering : List (CE.Group (CE.Stack Datum) CE.Any (Maybe Float) Datum) }


init : Model
init =
  { hovering = [] }


type Msg
  = OnHover (List (CE.Group (CE.Stack Datum) CE.Any (Maybe Float) Datum))


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
    , CE.onMouseMove OnHover (CE.getNearest CE.stack)
    , CE.onMouseLeave (OnHover [])
    ]
    [ C.grid []
    , C.xLabels []
    , C.yLabels []
    , C.series .x
        [ C.stacked
          [ C.interpolated .y
              [ CA.monotone, CA.opacity 0.2 ]
              [ CA.circle, CA.color "white", CA.border CA.pink, CA.borderWidth 1 ]
          , C.interpolated .z
              [ CA.monotone, CA.opacity 0, CA.color CA.pink ]
              [ CA.circle, CA.color "white", CA.border CA.pink, CA.borderWidth 1 ]
          ]
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
  , name = "Basic tooltip for area charts"
  , description = "Add tooltip for nearest stack in line or scatter chart."
  , order = 5
  }


type alias Datum =
  { x : Float
  , y : Float
  , z : Float
  , v : Float
  , w : Float
  , p : Float
  , q : Float
  }


data : List Datum
data =
  [ Datum 1  2 1 4.6 6.9 7.3 8.0
  , Datum 2  3 2 5.2 6.2 7.0 8.7
  , Datum 3  4 3 5.5 5.2 7.2 8.1
  , Datum 4  3 4 5.3 5.7 6.2 7.8
  , Datum 5  2 3 4.9 5.9 6.7 8.2
  , Datum 6  4 1 4.8 5.4 7.2 8.3
  , Datum 7  5 2 5.3 5.1 7.8 7.1
  , Datum 8  6 3 5.4 3.9 7.6 8.5
  , Datum 9  5 4 5.8 4.6 6.5 6.9
  , Datum 10 4 3 4.5 5.3 6.3 7.0
  ]

