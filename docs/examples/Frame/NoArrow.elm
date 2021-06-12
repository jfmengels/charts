module Examples.Frame.NoArrow exposing (..)

{-| @LARGE -}
import Html as H
import Svg as S
import Chart as C
import Chart.Attributes as CA


view : Model -> H.Html Msg
view model =
{-| @SMALL -}
  C.chart
    [ CA.height 300
    , CA.width 300
    ]
    [ C.grid []
    , C.xAxis [ CA.noArrow ]
    , C.xTicks []
    , C.xLabels []
    ]
{-| @SMALL END -}
{-| @LARGE END -}


meta =
  { category = "Frame and navigation"
  , categoryOrder = 4
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

