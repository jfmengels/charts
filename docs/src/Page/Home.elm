module Page.Home exposing (Model, Params, Msg, init, subscriptions, exit, update, view)


import Browser exposing (Document)
import Route exposing (Route)
import Session exposing (Session)
import Browser.Navigation as Navigation
import Charts.Landing as Landing
import Charts.Dashboard1 as Dashboard1
import Charts.Dashboard2 as Dashboard2
import Charts.Dashboard3 as Dashboard3
import Charts.Dashboard4 as Dashboard4
import Charts.Dashboard5 as Dashboard5
import Charts.Dashboard6 as Dashboard6
import Charts.Dashboard7 as Dashboard7
import Examples.Frontpage.Familiar as Familiar
import Examples.Frontpage.Concise as Concise
import Html as H
import Element as E
import Element.Font as F
import Element.Border as B
import Element.Background as BG
import Ui.Layout as Layout
import Ui.CompactExample as CompactExample
import Ui.Code as Code
import Ui.Menu as Menu

import Html as H
import Html.Attributes as HA
import Html.Events as HE
import Svg as S
import Svg.Attributes as SA

import Chart as C
import Chart.Attributes as CA
import Chart.Events as CE
import Chart.Svg as CS



-- MODEL


type alias Model =
  { dashboard1 : Dashboard1.Model
  , dashboard2 : Dashboard2.Model
  , dashboard3 : Dashboard3.Model
  , dashboard4 : Dashboard4.Model
  , dashboard5 : Dashboard5.Model
  , dashboard6 : Dashboard6.Model
  , dashboard7 : Dashboard7.Model
  , landing : Landing.Model
  , concise : Concise.Model
  , hovering : List (CE.Product CE.Any (Maybe Float) { year : Float, income : Float})
  }


type alias Params =
  ()



-- INIT


init : Navigation.Key -> Session -> Params -> ( Model, Cmd Msg )
init key session params =
  ( { dashboard1 = Dashboard1.init
    , dashboard2 = Dashboard2.init
    , dashboard3 = Dashboard3.init
    , dashboard4 = Dashboard4.init
    , dashboard5 = Dashboard5.init
    , dashboard6 = Dashboard6.init
    , dashboard7 = Dashboard7.init
    , landing = Landing.init
    , concise = Concise.init
    , hovering = []
    }
  , Cmd.none
  )


exit : Model -> Session -> Session
exit model session =
  session



-- UPDATE


type Msg
  = Dashboard1Msg Dashboard1.Msg
  | Dashboard2Msg Dashboard2.Msg
  | Dashboard3Msg Dashboard3.Msg
  | Dashboard4Msg Dashboard4.Msg
  | Dashboard5Msg Dashboard5.Msg
  | Dashboard6Msg Dashboard6.Msg
  | Dashboard7Msg Dashboard7.Msg
  | LandingMsg Landing.Msg
  | ConciseMsg Concise.Msg
  | OnHover (List (CE.Product CE.Any (Maybe Float) { year : Float, income : Float}))
  | None



update : Navigation.Key -> Msg -> Model -> ( Model, Cmd Msg )
update key msg model =
  case msg of
    Dashboard1Msg subMsg ->
      ( { model | dashboard1 = Dashboard1.update subMsg model.dashboard1 }, Cmd.none )

    Dashboard2Msg subMsg ->
      ( { model | dashboard2 = Dashboard2.update subMsg model.dashboard2 }, Cmd.none )

    Dashboard3Msg subMsg ->
      ( { model | dashboard3 = Dashboard3.update subMsg model.dashboard3 }, Cmd.none )

    Dashboard4Msg subMsg ->
      ( { model | dashboard4 = Dashboard4.update subMsg model.dashboard4 }, Cmd.none )

    Dashboard5Msg subMsg ->
      ( { model | dashboard5 = Dashboard5.update subMsg model.dashboard5 }, Cmd.none )

    Dashboard6Msg subMsg ->
      ( { model | dashboard6 = Dashboard6.update subMsg model.dashboard6 }, Cmd.none )

    Dashboard7Msg subMsg ->
      ( { model | dashboard7 = Dashboard7.update subMsg model.dashboard7 }, Cmd.none )

    ConciseMsg subMsg ->
      ( { model | concise = Concise.update subMsg model.concise }, Cmd.none )

    LandingMsg subMsg ->
      ( { model | landing = Landing.update subMsg model.landing }, Cmd.none )

    OnHover hovering ->
      ( { model | hovering = hovering }, Cmd.none )

    None ->
      ( model, Cmd.none)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    { title = "elm-charts"
    , body =
        Layout.view
          [ Menu.small

          , E.el [] (E.html <| H.map LandingMsg (Landing.view model.landing))

          , E.column
              [ E.width E.fill
              , E.spacing 100
              , E.paddingXY 0 100
              ]
              [ feature
                  { title = "Beginner friendly"
                  , body = "The API mirrors the element and attribute pattern which you already know and love."
                  , chart = H.map (\_ -> None) (Familiar.view ())
                  , code = Familiar.smallCode
                  }

              , feature
                  { title = "Advanced chart, elegant code"
                  , body = "No clutter even with tricky details!"
                  , chart = H.map ConciseMsg (Concise.view model.concise)
                  , code = Concise.smallCode
                  }

              , feature
                  { title = "Visual documentation"
                  , body = "You never need to know how SVG clip paths work or any SVG for that matter!"
                  , chart = H.map (\_ -> None) (Familiar.view ())
                  , code = Familiar.smallCode
                  }
              ]
          ]
    }


feature : { title : String, body : String, chart : H.Html msg, code : String } -> E.Element msg
feature config =
  E.column
    [ E.width E.fill
    , E.spacing 10
    ]
    [ E.el
        [ E.width E.fill
        , F.size 40
        ]
        (E.text config.title)
    , E.paragraph
        [ F.size 14
        , F.color (E.rgb255 120 120 120)
        , E.paddingXY 0 10
        ]
        [ E.text config.body ]
    , E.row
        [ E.width E.fill
        , E.spacing 40
        , E.paddingXY 0 15
        ]
        [ E.el [ E.alignTop ] (E.html config.chart)
        , E.el
            [ E.width E.fill
            , E.height E.fill
            , BG.color (E.rgb255 250 250 250)
            ]
            (Code.view { template = config.code, edits = [] })
        ]
    ]


section : Int -> H.Html msg -> E.Element msg
section portion chart =
  E.column
    [ E.alignTop
    , E.width (E.fillPortion portion)
    ]
    [ E.html chart
    ]