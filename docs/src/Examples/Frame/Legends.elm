module Examples.Frame.Legends exposing (..)


-- THIS IS A GENERATED MODULE!

import Html as H
import Html.Attributes as HA
import Svg as S
import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    , CA.margin { top = 30, bottom = 0, left = 0, right = 0 }
    ]
    [ C.grid []
    , C.xAxis []
    , C.yLabels [ CA.pinned .min ]
    , C.xLabels [ CA.noGrid ]

    -- BAR CHART
    , C.bars
        [ CA.roundTop 0.3 ]
        [ C.named "B1" <| C.bar .z []
        , C.named "B2" <| C.bar .y [ CA.striped [] ]
        ]
        data

    -- LINE CHART
    , C.series .x
        [ C.named "A1" <|
            C.interpolated .p
              [  ]
              [ CA.cross, CA.borderWidth 2, CA.border "white" ]
        , C.named "A2" <|
            C.interpolated .q
              [  ]
              [ CA.cross, CA.borderWidth 2, CA.border "white" ]
        ]
        data

    -- LEGENDS
    , C.legendsAt .min .max
        [ CA.row
        , CA.moveRight 10
        , CA.moveUp 25
        , CA.spacing 15
        ]
        [ CA.width 20 ]
    ]


meta =
  { category = "Navigation"
  , categoryOrder = 4
  , name = "Legends"
  , description = "Add legends to chart."
  , order = 21
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
  , Datum 3  3 4 5.3 5.7 6.2 7.8
  , Datum 4  4 1 4.8 5.4 7.2 8.3
  , Datum 5  6 3 5.4 3.9 7.6 8.5
  , Datum 6 4 3 4.5 5.3 6.3 7.0
  ]



smallCode : String
smallCode =
  """
  C.chart
    [ CA.height 300
    , CA.width 300
    , CA.margin { top = 30, bottom = 0, left = 0, right = 0 }
    ]
    [ C.grid []
    , C.xAxis []
    , C.yLabels [ CA.pinned .min ]
    , C.xLabels [ CA.noGrid ]

    -- BAR CHART
    , C.bars
        [ CA.roundTop 0.3 ]
        [ C.named "B1" <| C.bar .z []
        , C.named "B2" <| C.bar .y [ CA.striped [] ]
        ]
        data

    -- LINE CHART
    , C.series .x
        [ C.named "A1" <|
            C.interpolated .p
              [  ]
              [ CA.cross, CA.borderWidth 2, CA.border "white" ]
        , C.named "A2" <|
            C.interpolated .q
              [  ]
              [ CA.cross, CA.borderWidth 2, CA.border "white" ]
        ]
        data

    -- LEGENDS
    , C.legendsAt .min .max
        [ CA.row
        , CA.moveRight 10
        , CA.moveUp 25
        , CA.spacing 15
        ]
        [ CA.width 20 ]
    ]
  """


largeCode : String
largeCode =
  """
import Html as H
import Html.Attributes as HA
import Svg as S
import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE


view : Model -> H.Html Msg
view model =
  C.chart
    [ CA.height 300
    , CA.width 300
    , CA.margin { top = 30, bottom = 0, left = 0, right = 0 }
    ]
    [ C.grid []
    , C.xAxis []
    , C.yLabels [ CA.pinned .min ]
    , C.xLabels [ CA.noGrid ]

    -- BAR CHART
    , C.bars
        [ CA.roundTop 0.3 ]
        [ C.named "B1" <| C.bar .z []
        , C.named "B2" <| C.bar .y [ CA.striped [] ]
        ]
        data

    -- LINE CHART
    , C.series .x
        [ C.named "A1" <|
            C.interpolated .p
              [  ]
              [ CA.cross, CA.borderWidth 2, CA.border "white" ]
        , C.named "A2" <|
            C.interpolated .q
              [  ]
              [ CA.cross, CA.borderWidth 2, CA.border "white" ]
        ]
        data

    -- LEGENDS
    , C.legendsAt .min .max
        [ CA.row
        , CA.moveRight 10
        , CA.moveUp 25
        , CA.spacing 15
        ]
        [ CA.width 20 ]
    ]
  """