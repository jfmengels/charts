module Test exposing (..)

import Html as H
import Html.Attributes as HA
import Svg as S exposing (Svg, svg, g, circle, text_, text)
import Svg.Attributes as SA exposing (width, height, stroke, fill, r, transform)
import Svg.Coordinates as Coordinates
import Chart as C
import Svg.Chart as SC
import Browser
import Time
import Data.Iris as Iris
import Data.Salery as Salery
import Data.Education as Education
import Dict
import Internal.Chart as I


-- TODO
-- labels + ticks + grid automation?
-- clean up Item / Items
-- Title
-- seperate areas from lines + dots to fix opacity


main =
  Browser.sandbox
    { init = init
    , update = update
    , view = view
    }


type alias Model =
  { hoveringSalery : List (SC.Item Float SC.BarDetails Salery.Datum)
  , hovering : List (SC.Item Float SC.BarDetails Datum)
  , point : Maybe SC.Point
  }


init : Model
init =
  Model [] [] Nothing


type Msg
  = OnHoverSalery (List (SC.Item Float SC.BarDetails Salery.Datum))
  | OnHover (List (SC.Item Float SC.BarDetails Datum))
  | OnCoords SC.Point -- TODO


update : Msg -> Model -> Model
update msg model =
  case msg of
    OnHoverSalery bs -> { model | hoveringSalery = bs }
    OnHover bs -> { model | hovering = bs }
    OnCoords p -> { model | point = Just p }


type alias Datum =
  { x : Float
  , y : Maybe Float
  , z : Maybe Float
  , label : String
  }


data : List Datum
data =
  [ { x = 2, y = Just 6, z = Just 5, label = "DK" }
  , { x = 6, y = Just 5, z = Just 5, label = "SE" }
  , { x = 8, y = Just 3, z = Just 2, label = "FI" }
  , { x = 10, y = Just 4, z = Just 3, label = "IS" }
  ]


view : Model -> H.Html Msg
view model =
  H.div
    [ HA.style "font-size" "12px"
    , HA.style "font-family" "monospace"
    , HA.style "margin" "0 auto"
    , HA.style "padding-top" "50px"
    , HA.style "width" "100vw"
    , HA.style "max-width" "1000px"
    ]
    [ C.chart
      [ C.height 400
      , C.width 1000
      , C.static
      , C.marginLeft 50
      , C.paddingTop 15
      , C.range (C.startMin 0 >> C.endMax 6)
      , C.domain (C.startMax 8 >> C.endMin 18)
      , C.id "salery-discrepancy"
      ]
      [ C.grid []

      --, C.bars
      --    [ C.start (\d -> d.x - 2)
      --    , C.end .x
      --    , C.rounded 0.2
      --    , C.roundBottom
      --    , C.grouped
      --    ]
      --    [ C.stacked
      --        [ C.property .y [] (always [])
      --        , C.property .z [ C.color C.pink ] (always [])
      --        , C.property (C.just .x) [ C.color C.purple ] (always [])
      --        ]
      --    , C.property .z [ C.color C.purple ] (always [])
      --    ]
      --    data

      , C.yAxis [ C.noArrow ]
      , C.xTicks []
      , C.xLabels []
      , C.yLabels [ C.ints ]
      , C.yTicks [ C.ints ]


      --, C.series .x
      --    --[ C.monotone ]
      --    [ C.stacked
      --        [ C.property .y [ C.area 0.2, C.monotone 1, C.color C.purple ] (always [])
      --            --(\d -> if hovered d then [ C.aura 5 0.5 ] else [])
      --        , C.property .z [ C.monotone 1, C.color C.purple ] (always [])
      --        ]
      --    ]
      --    data

      , C.svg <| \p ->
          S.g []
            -- I.label p [ I.x 2, I.y 15, I.yOff -5, I.xOff 5, I.border "blue", I.fontSize 60, I.borderWidth 2, I.color "pink" ] "hello"
            [
            -- I.line p [ I.x1 4, I.x2 6, I.color "blue", I.width 2 ]
            --, I.arrow p [ I.x p.x.max, I.y p.y.min ]
            --, I.bar p [ I.x1 2.5, I.x2 3, I.y2 2, I.color "#6761ff", I.borderWidth 1, I.border "white", I.roundBottom 0.1, I.roundTop 0.1 ]
            --, I.bar p [ I.x1 2.5, I.x2 3, I.y1 2, I.y2 10, I.color "#fa55f0", I.borderWidth 10, I.border "#fa55f087", I.roundBottom 0.1, I.roundTop 0.1 ]
            --, I.cross p [ I.x 2, I.y 15, I.border "rgb(5, 142, 218)", I.opacity 1, I.size 40, I.borderWidth 1, I.border "white", I.aura 0.5, I.auraWidth 5 ]
            --,
              I.interpolation p .x .y
                [ I.monotone ]
                [ { x = 0, y = Just 14 }
                , { x = 0.5, y = Just 16 }
                , { x = 0.75, y = Just 14 }
                , { x = 1, y = Nothing }
                , { x = 1.4, y = Just 13 }
                , { x = 2, y = Just 14 }
                , { x = 3, y = Just 16 }
                , { x = 4, y = Just 13 }
                , { x = 5, y = Just 14 }
                , { x = 6, y = Just 10 }
                ]

            , I.interpolation p .x (.y >> Maybe.map (\d -> if remainderBy 2 (round d) == 0 then d - 1 else d - 2))
                [ I.monotone ]
                [ { x = 0, y = Just 14 }
                , { x = 0.5, y = Just 16 }
                , { x = 0.75, y = Just 14 }
                , { x = 1, y = Nothing }
                , { x = 1.4, y = Just 13 }
                , { x = 2, y = Just 14 }
                , { x = 3, y = Just 16 }
                , { x = 4, y = Just 13 }
                , { x = 5, y = Just 14 }
                , { x = 6, y = Just 10 }
                ]

            , I.area p .x (Just (.y >> Maybe.map (\d -> if remainderBy 2 (round d) == 0 then d - 1 else d - 2))) .y --
                [ I.monotone ]
                [ { x = 0, y = Just 14 }
                , { x = 0.5, y = Just 16 }
                , { x = 0.75, y = Just 14 }
                , { x = 1, y = Nothing }
                , { x = 1.4, y = Just 13 }
                , { x = 2, y = Just 14 }
                , { x = 3, y = Just 16 }
                , { x = 4, y = Just 13 }
                , { x = 5, y = Just 14 }
                , { x = 6, y = Just 10 }
                ]
            ]

      , C.xAxis [ C.noArrow ]
      ]
    ]
