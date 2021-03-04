module HighLevel exposing (..)

import Html
import Html.Attributes as HA
import Svg exposing (Svg, svg, g, circle, text_, text)
import Svg.Attributes exposing (width, height, stroke, fill, r, transform)
import Svg.Coordinates as Coordinates
import Chart as C
import Svg.Chart as SC
import Browser



main =
  Browser.sandbox
    { init = Nothing
    , update = \msg model ->
        case msg of
          OnHover p -> p
          OnLeave -> Nothing

    , view = view
    }


type Msg
  = OnHover (Maybe Point)
  | OnLeave


type alias Point =
  { x : Float
  , y : Float
  }


data : List Point
data =
  [ { x = -4, y = 4 }
  , { x = -2, y = 3 }
  , { x = 0, y = -4 }
  , { x = 4, y = -4 }
  , { x = 6, y = 4 }
  , { x = 8, y = 3 }
  , { x = 10, y = -4 }
  ]


view : Maybe Point -> Html.Html Msg
view hovered =
  let specialDot p =
        if Maybe.map .x hovered == Just p.x
          then SC.aura 2 8 0.2 SC.circle "rgb(5,142,218)"
          else SC.disconnected 2 1 SC.circle "rgb(5,142,218)"
  in
  C.chart
    [ C.width 500
    , C.height 300
    , C.marginTop 30
    , C.marginRight 10
    , C.responsive
    , C.range (C.fromData .x data)
    , C.domain (C.fromData .y data)
    , C.id "some-id"
    , C.htmlAttrs
        [ HA.style "font-size" "12px"
        , HA.style "font-family" "monospace"
        , HA.style "margin" "20px 40px"
        ]
    , C.events
        [ C.event "mousemove" (C.getNearest OnHover .x .y data)
        , C.event "mouseleave" (\_ _ -> OnLeave)
        ]
    ]
    [ C.grid [ C.dotted, C.width 0.4, C.color "rgb(220,220,220)" ] (C.ints 12 String.fromInt) (C.ints 5 String.fromInt)
    , C.xAxis [ C.pinned (always 0) ]
    , C.xTicks [ C.pinned (always 0) ] (C.ints 12 String.fromInt)
    , C.xLabels [] (C.floats 12 String.fromFloat)
    , C.yAxis [ C.pinned (always 0) ]
    , C.yTicks [ C.pinned (always 0) ] (C.ints 5 String.fromInt)
    , C.yLabels [] (C.ints 5 String.fromInt)
    , C.monotone .x .y [ C.dot specialDot, C.area "rgba(5, 142, 218, 0.25)" ] data
    --, C.scatter .x .y [ C.dot specialDot ] data
    , case hovered of
        Just point ->
          C.tooltip point.x point.y []
            [ Html.text ("( " ++ String.fromFloat point.x ++ ", " ++ String.fromFloat point.y ++ " )") ]

        Nothing ->
          C.none
    ]




