module Chart exposing
  ( chart

  , Element, bars, series, seriesMap, barsMap
  , Property, bar, scatter, interpolated
  , barMaybe, scatterMaybe, interpolatedMaybe
  , stacked, named, variation, amongst

  , xAxis, yAxis, xTicks, yTicks, xLabels, yLabels, grid
  , binLabels, barLabels, dotLabels

  , xLabel, yLabel, xTick, yTick
  , generate, floats, ints, times
  , label, labelAt, legendsAt

  , tooltip, line, rect, none

  , svg, svgAt, html, htmlAt

  , each, eachBin, eachStack, eachBar, eachDot, eachProduct, eachCustom
  , withPlane, withBins, withStacks, withBars, withDots, withProducts

  , binned
  )


{-| The configuration of this charting library mirrors the pattern of HTML elements
and attributes. It looks something like this:

    import Html exposing (Html)
    import Chart as C
    import Chart.Attributes as CA

    view : Html msg
    view =
      C.chart
        [ CA.width 300
        , CA.height 300
        ]
        [ C.grid []
        , C.xLabels []
        , C.yLabels []
        , C.bars []
            [ C.bar .income [ CA.color "red" ]
            , C.bar .spending [ CA.opacity 0.8 ]
            ]
            data
        ]

All the elements, like `chart`, `grid`, `xLabels`, `yLabels`, `bars` and `bar` in the example
above, are defined in this module. All the attributes, like `width`, `height`, `color`, and `opacity`,
are defined in `Chart.Attributes`. Attributes and other functions related to events are located in
the `Chart.Events` module. Lastly, `Chart.Svg` holds charting primitives if case your have very special
needs.

NOTE: Some of the more advanced elements utilize helper functions in `Chart.Events`
too. If that is the case, I will make a note in the comment of the element.

In the following examples, I will assume the imports:

    import Html as H
    import Html.Attributes as HA
    import Html.Events as HE
    import Svg as S
    import Svg.Attributes as SA
    import Svg.Events as SE
    import Chart as C
    import Chart.Attributes as CA
    import Chart.Events as CE


## Visual examples and documentation

For additional examples and documnetation of features, please check out [elm-charts.org](https://www.elm-charts.org/documentation).


# The frame
@docs chart
@docs Element

# Chart elements

## Bar charts
@docs bars, barsMap, bar, barMaybe

## Scatter and line charts
@docs series, seriesMap, scatter, scatterMaybe, interpolated, interpolatedMaybe

## Stacking, naming, and variation
@docs Property, stacked, named, variation, amongst

# Navigation elements

## Axis lines
@docs xAxis, yAxis

## Axis ticks
@docs xTicks, yTicks

## Axis labels
@docs xLabels, yLabels

## Grid
@docs grid

## Custom Axis labels and ticks
@docs xLabel, yLabel, xTick, yTick
@docs generate, floats, ints, times

## Data labels
@docs binLabels, barLabels, dotLabels

## General labels
@docs label, labelAt

## Legends
@docs legendsAt

## Other navigation helpers
@docs tooltip, line, rect

# Arbitrary elements
@docs svgAt, htmlAt, svg, html, none

# Advanced elements

## For each item, do..
@docs eachBin, eachStack, eachBar, eachDot, eachProduct, each, eachCustom

## With all item, do..
@docs withBins, withStacks, withBars, withDots, withProducts

## Using the plane, do..
@docs withPlane

# Data helper
@docs binned

-}


import Internal.Coordinates as C
import Svg as S
import Svg.Attributes as SA
import Svg.Events as SE
import Html as H
import Html.Attributes as HA
import Intervals as I
import Internal.Property as P
import Time
import Dict exposing (Dict)
import Internal.Item as Item
import Internal.Produce as Produce
import Internal.Legend as Legend
import Internal.Group as Group
import Internal.Helpers as Helpers
import Internal.Svg as IS
import Internal.Events as IE
import Chart.Svg as CS
import Chart.Attributes as CA
import Chart.Events as CE


{-| -}
type alias Container data msg =
  { width : Float
  , height : Float
  , margin : { top : Float, bottom : Float, left : Float, right : Float }
  , padding : { top : Float, bottom : Float, left : Float, right : Float }
  , responsive : Bool
  , range : List (CA.Attribute C.Axis)
  , domain : List (CA.Attribute C.Axis)
  , events : List (CE.Event data msg)
  , htmlAttrs : List (H.Attribute msg)
  , attrs : List (S.Attribute msg)
  }


{-| This is the root element of your chart. All your chart elements must be contained in
a `chart` element. The below example illustrates what configurations are available for
the `chart` element.

    import Html exposing (Html)
    import Html.Attributes as HA
    import Svg.Attributes as SA
    import Chart as C
    import Chart.Attributes as CA
    import Chart.Events as CE

    view : Html msg
    view =
      C.chart
        [ CA.width 300    -- Sets width of chart
        , CA.height 500   -- Sets height of chart
        , CA.static       -- Don't scale with parent container

        , CA.margin { top = 10, bottom = 20, left = 20, right = 20 }
                          -- Add space around your chart.
                          -- Useful if you have labels which extend
                          -- outside the main chart area.

        , CA.padding { top = 10, bottom = 10, left = 10, right = 10 }
                          -- Expand your domain / range by a set
                          -- amount of SVG units.
                          -- Useful if you have e.g. scatter dots
                          -- which extend beyond your main chart area,
                          -- and you'd like them to be within.

        -- Control the range and domain of your chart.
        -- Your range and domain is by default set to the limits of
        -- your data, but you can change them like this:
        , CA.range
            [ CA.lowest -5 CA.orLower
                -- Makes sure that your x-axis begins at -5 or lower, no matter
                -- what your data is like.
            , CA.highest 10 CA.orHigher
                -- Makes sure that your x-axis ends at 10 or higher, no matter
                -- what your data is like.
            ]
        , CA.domain
            [ CA.lowest 0 CA.exactly ]
                -- Makes sure that your y-axis begins at exactly 0, no matter
                -- what your data is like.

        -- Add event triggers to your chart. Learn move about these in
        -- the `Chart.Events` module.
        , CE.onMouseMove OnHovering (CE.getNearest C.bar)
        , CE.onMouseLeave (OnHovering [])

        -- Add arbitrary HTML and SVG attributes to your chart.
        , CA.htmlAttrs [ HA.style "background" "beige" ]
        , CA.attrs [ SA.id "my-chart" ]
        ]
        [ C.grid []
        , C.xLabels []
        , C.yLabels []
        , ..
        ]

-}
chart : List (CA.Attribute (Container data msg)) -> List (Element data msg) -> H.Html msg
chart edits unindexedElements =
  let config =
        Helpers.apply edits
          { width = 300
          , height = 300
          , margin = { top = 0, bottom = 0, left = 0, right = 0 }
          , padding = { top = 0, bottom = 0, left = 0, right = 0 }
          , responsive = True
          , range = []
          , domain = []
          , events = []
          , attrs = [ SA.style "overflow: visible;" ]
          , htmlAttrs = []
          }

      elements =
        let toIndexedEl el ( acc, index ) =
              case el of
                Indexed toElAndIndex ->
                  let ( newEl, newIndex ) = toElAndIndex index in
                  ( acc ++ [ newEl ], newIndex )

                _ ->
                  ( acc ++ [ el ], index )
        in
        List.foldl toIndexedEl ( [], 0 ) unindexedElements
          |> Tuple.first

      plane =
        definePlane config elements

      items =
        getItems plane elements

      legends_ =
        getLegends elements

      tickValues =
        getTickValues plane items elements

      ( beforeEls, chartEls, afterEls ) =
        viewElements config plane tickValues items legends_ elements

      toEvent (IE.Event event_) =
        let (IE.Decoder decoder) = event_.decoder in
        IS.Event event_.name (decoder items)
  in
  IS.container plane
    { attrs = config.attrs
    , htmlAttrs = config.htmlAttrs
    , responsive = config.responsive
    , events = List.map toEvent config.events
    }
    beforeEls
    chartEls
    afterEls



-- ELEMENTS


{-| The representation of a chart element.

-}
type Element data msg
  = Indexed (Int -> ( Element data msg, Int ))
  | SeriesElement
      (List C.Position)
      (List (Item.Product CE.Any (Maybe Float) data))
      (List Legend.Legend)
      (C.Plane -> S.Svg msg)
  | BarsElement
      (List C.Position)
      (List (Item.Product CE.Any (Maybe Float) data))
      (List Legend.Legend)
      (C.Plane -> TickValues -> TickValues)
      (C.Plane -> S.Svg msg)
  | AxisElement
      (C.Plane -> TickValues -> TickValues)
      (C.Plane -> S.Svg msg)
  | TicksElement
      (C.Plane -> TickValues -> TickValues)
      (C.Plane -> S.Svg msg)
  | TickElement
      (C.Plane -> Tick)
      (C.Plane -> Tick -> TickValues -> TickValues)
      (C.Plane -> Tick -> S.Svg msg)
  | LabelsElement
      (C.Plane -> Labels)
      (C.Plane -> Labels -> TickValues -> TickValues)
      (C.Plane -> Labels -> S.Svg msg)
  | LabelElement
      (C.Plane -> Label)
      (C.Plane -> Label -> TickValues -> TickValues)
      (C.Plane -> Label -> S.Svg msg)
  | GridElement
      (C.Plane -> TickValues -> S.Svg msg)
  | SubElements
      (C.Plane -> List (Item.Product CE.Any (Maybe Float) data) -> List (Element data msg))
  | ListOfElements
      (List (Element data msg))
  | SvgElement
      (C.Plane -> S.Svg msg)
  | HtmlElement
      (C.Plane -> List Legend.Legend -> H.Html msg)


definePlane : Container data msg -> List (Element data msg) -> C.Plane
definePlane config elements =
  let collectLimits el acc =
        case el of
          Indexed _ -> acc
          SeriesElement lims _ _ _ -> acc ++ lims
          BarsElement lims _ _ _ _ -> acc ++ lims
          AxisElement _ _ -> acc
          TicksElement _ _ -> acc
          TickElement _ _ _ -> acc
          LabelsElement _ _ _ -> acc
          LabelElement _ _ _ -> acc
          GridElement _ -> acc
          SubElements _ -> acc
          ListOfElements subs -> List.foldl collectLimits acc subs
          SvgElement _ -> acc
          HtmlElement _ -> acc

      limits_ =
        List.foldl collectLimits [] elements
          |> C.foldPosition identity
          |> \pos -> { x = toLimit pos.x1 pos.x2, y = toLimit pos.y1 pos.y2 }
          |> \{ x, y } -> { x = fixSingles x, y = fixSingles y }

      toLimit min max =
        { min = min, max = max, dataMin = min, dataMax = max }

      fixSingles bs =
        if bs.min == bs.max then { bs | max = bs.min + 10 } else bs

      calcRange =
        case config.range of
          [] -> limits_.x
          some -> List.foldl (\f b -> f b) limits_.x some

      calcDomain =
        case config.domain of
          [] -> CA.lowest 0 CA.orLower limits_.y
          some -> List.foldl (\f b -> f b) limits_.y some

      unpadded =
        { width = max 1 (config.width - config.padding.left - config.padding.right)
        , height = max 1 (config.height - config.padding.bottom - config.padding.top)
        , margin = config.margin
        , x = calcRange
        , y = calcDomain
        }

      scalePadX =
        C.scaleCartesianX unpadded

      scalePadY =
        C.scaleCartesianY unpadded

      xMin = calcRange.min - scalePadX config.padding.left
      xMax = calcRange.max + scalePadX config.padding.right

      yMin = calcDomain.min - scalePadY config.padding.bottom
      yMax = calcDomain.max + scalePadY config.padding.top
  in
  { width = config.width
  , height = config.height
  , margin = config.margin
  , x =
      { calcRange
      | min = min xMin xMax
      , max = max xMin xMax
      }
  , y =
      { calcDomain
      | min = min yMin yMax
      , max = max yMin yMax
      }
  }


getItems : C.Plane -> List (Element data msg) -> List (Item.Product CE.Any (Maybe Float) data)
getItems plane elements =
  let toItems el acc =
        case el of
          Indexed _ -> acc
          SeriesElement _ items _ _ -> acc ++ items
          BarsElement _ items _ _ _ -> acc ++ items
          AxisElement func _ -> acc
          TicksElement _ _ -> acc
          TickElement _ _ _ -> acc
          LabelsElement _ _ _ -> acc
          LabelElement _ _ _ -> acc
          GridElement _ -> acc
          SubElements _ -> acc -- TODO add phantom type to only allow decorative els in this
          ListOfElements subs -> List.foldl toItems acc subs
          SvgElement _ -> acc
          HtmlElement _ -> acc
  in
  List.foldl toItems [] elements


getLegends : List (Element data msg) -> List Legend.Legend
getLegends elements =
  let toLegends el acc =
        case el of
          Indexed _ -> acc
          SeriesElement _ _ legends_ _ -> acc ++ legends_
          BarsElement _ _ legends_ _ _ -> acc ++ legends_
          AxisElement _ _ -> acc
          TicksElement _ _ -> acc
          TickElement _ _ _ -> acc
          LabelsElement _ _ _ -> acc
          LabelElement _ _ _ -> acc
          GridElement _ -> acc
          SubElements _ -> acc
          ListOfElements subs -> List.foldl toLegends acc subs
          SvgElement _ -> acc
          HtmlElement _ -> acc
  in
  List.foldl toLegends [] elements



{-| -}
type alias TickValues =
  { xAxis : List Float
  , yAxis : List Float
  , xs : List Float
  , ys : List Float
  }


getTickValues : C.Plane -> List (Item.Product CE.Any (Maybe Float) data) -> List (Element data msg) -> TickValues
getTickValues plane items elements =
  let toValues el acc =
        case el of
          Indexed _ -> acc
          SeriesElement _ _ _ _     -> acc
          BarsElement _ _ _ func _  -> func plane acc
          AxisElement func _        -> func plane acc
          TicksElement func _       -> func plane acc
          TickElement toC func _    -> func plane (toC plane) acc
          LabelsElement toC func _  -> func plane (toC plane) acc
          LabelElement toC func _   -> func plane (toC plane) acc
          SubElements func          -> List.foldl toValues acc (func plane items)
          GridElement _             -> acc
          ListOfElements subs       -> List.foldl toValues acc subs
          SvgElement _              -> acc
          HtmlElement _             -> acc
  in
  List.foldl toValues (TickValues [] [] [] []) elements


viewElements : Container data msg -> C.Plane -> TickValues -> List (Item.Product CE.Any (Maybe Float) data) -> List Legend.Legend -> List (Element data msg) -> ( List (H.Html msg), List (S.Svg msg), List (H.Html msg) )
viewElements config plane tickValues allItems allLegends elements =
  let viewOne el ( before, chart_, after ) =
        case el of
          Indexed _                 -> ( before,chart_, after )
          SeriesElement _ _ _ view  -> ( before, view plane :: chart_, after )
          BarsElement _ _ _ _ view  -> ( before, view plane :: chart_, after )
          AxisElement _ view        -> ( before, view plane :: chart_, after )
          TicksElement _ view       -> ( before, view plane :: chart_, after )
          TickElement toC _ view    -> ( before, view plane (toC plane) :: chart_, after )
          LabelsElement toC _ view  -> ( before, view plane (toC plane) :: chart_, after )
          LabelElement toC _ view   -> ( before, view plane (toC plane) :: chart_, after )
          GridElement view          -> ( before, view plane tickValues :: chart_, after )
          SubElements func          -> List.foldr viewOne ( before, chart_, after ) (func plane allItems)
          ListOfElements els        -> List.foldr viewOne ( before, chart_, after ) els
          SvgElement view           -> ( before, view plane :: chart_, after )
          HtmlElement view          ->
            ( if List.length chart_ > 0 then view plane allLegends :: before else before
            , chart_
            , if List.length chart_ > 0 then after else view plane allLegends :: after
            )
  in
  List.foldr viewOne ([], [], []) elements



 -- TOOLTIP


type alias Tooltip =
  { direction : Maybe IS.Direction
  , focal : Maybe (C.Position -> C.Position)
  , height : Float
  , width : Float
  , offset : Float
  , arrow : Bool
  , border : String
  , background : String
  }


{-| Add a tooltip for a specific item.

    C.chart
      [ CE.onMouseMove OnHover (CE.getNearest CE.product) ]
      [ C.series .year
          [ C.scatter .income [] ]
          [ { year = 2000, income = 40000 }
          , { year = 2010, income = 56000 }
          , { year = 2020, income = 62000 }
          ]

      , C.each model.hovering <| \plane product ->
          [ C.tooltip product [] [] [] ]
      ]

Customizations:

    C.tooltip item
      [ -- Change direction
        CA.onTop          -- Always place tooltip on top of the item
      , CA.onBottom       -- Always place tooltip below of the item
      , CA.onRight        -- Always place tooltip on the right of the item
      , CA.onLeft         -- Always place tooltip on the left of the item
      , CA.onLeftOrRight  -- Place tooltip on the left or right of the item,
                          -- depending on which side has more space available
      , CA.onTopOrBottom  -- Place tooltip on the top or bottom of the item,
                          -- depending on which side has more space available

        -- Change focal point (where on the item the tooltip is achored)
      , CA.top
      , CA.bottom
      , CA.left
      , CA.right
      , CA.center
      , CA.topLeft
      , CA.topRight
      , CA.topCenter
      , CA.bottomLeft
      , CA.bottomRight
      , CA.bottomCenter
      , CA.leftCenter
      , CA.rightCenter

      , CA.offset 20  -- Change offset between focal point and tooltip
      , CA.noArrow    -- Remove little box arrow
      , CA.border "blue"  -- Change border color
      , CA.background     -- Change background color
      ]
      [] -- Add any HTML attributes
      [] -- Add any HTML children (Will be filled with default tooltip if left empty)


-}
tooltip : Item.Item a -> List (CA.Attribute Tooltip) -> List (H.Attribute Never) -> List (H.Html Never) -> Element data msg
tooltip i edits attrs_ content =
  html <| \p ->
    let pos = Item.getLimits i
        content_ = if content == [] then Item.toHtml i else content
    in
    if IS.isWithinPlane p pos.x1 pos.y2 -- TODO
    then CS.tooltip p (Item.getPosition p i) edits attrs_ content_
    else H.text ""



-- AXIS


{-| -}
type alias Axis =
  { limits : List (CA.Attribute C.Axis)
  , pinned : C.Axis -> Float
  , arrow : Bool
  , color : String
  , width : Float
  }


{-| Add an x-axis line to your chart. The example below illustrates
the styling options:

    C.chart []
      [ C.xAxis
          [ CA.color "red"  -- Change color of line
          , CA.width 2      -- Change width of line
          , CA.noArrow      -- Remove arrow from line
          , CA.pinned .max  -- Change what y position the axis is set at
                            -- .max is at the very top
                            -- .min is at the very bottom
                            -- CA.zero is the closest you can go to zero
                            -- (always 3) is at y = 3.

          , CA.limits
              [ CA.lowest 2 CA.exactly
              , CA.highest 8 CA.exactly
              ]
              -- Change from where to where you line goes.
              -- The example will make a line where x1 = 2 to x2 = 8
          ]
      ]

-}
xAxis : List (CA.Attribute Axis) -> Element item msg
xAxis edits =
  let config =
        Helpers.apply edits
          { limits = []
          , pinned = CA.zero
          , color = ""
          , arrow = True
          , width = 1
          }

      addTickValues p ts =
        { ts | yAxis = config.pinned p.y :: ts.yAxis }
  in
  AxisElement addTickValues <| \p ->
    let xLimit = List.foldl (\f x -> f x) p.x config.limits in
    S.g
      [ SA.class "elm-charts__x-axis" ]
      [ CS.line p
          [ CA.color config.color
          , CA.width config.width
          , CA.y1 (config.pinned p.y)
          , CA.x1 (max p.x.min xLimit.min)
          , CA.x2 (min p.x.max xLimit.max)
          ]
      , if config.arrow then
          CS.arrow p
            [ CA.color config.color ]
            { x = xLimit.max
            , y = config.pinned p.y
            }
        else
          S.text ""
      ]


{-| Add an y-axis line to your chart. The styling options are the same
as for `xAxis`.
-}
yAxis : List (CA.Attribute Axis) -> Element item msg
yAxis edits =
  let config =
        Helpers.apply edits
          { limits = []
          , pinned = CA.zero
          , color = ""
          , arrow = True
          , width = 1
          }

      addTickValues p ts =
        { ts | xAxis = config.pinned p.x :: ts.xAxis }
  in
  AxisElement addTickValues <| \p ->
    let yLimit = List.foldl (\f y -> f y) p.y config.limits in
    S.g
      [ SA.class "elm-charts__y-axis" ]
      [ CS.line p
          [ CA.color config.color
          , CA.width config.width
          , CA.x1 (config.pinned p.x)
          , CA.y1 (max p.y.min yLimit.min)
          , CA.y2 (min p.y.max yLimit.max)
          ]
      , if config.arrow then
          CS.arrow p [ CA.color config.color, CA.rotate -90 ]
            { x = config.pinned p.x
            , y = yLimit.max
            }
        else
          S.text ""
      ]


type alias Ticks =
  { color : String
  , height : Float
  , width : Float
  , pinned : C.Axis -> Float
  , limits : List (CA.Attribute C.Axis)
  , amount : Int
  , flip : Bool
  , grid : Bool
  , generate : IS.TickType
  }


{-| Produce a set of ticks at "nice" numbers on the x-axis of your chart.
The example below illustrates the configuration:

    C.chart []
      [ C.xTicks
          [ CA.color "red" -- Change color
          , CA.height 8    -- Change height
          , CA.width 2     -- Change width
          , CA.amount 15   -- Change amount of ticks
          , CA.flip        -- Flip to opposite direction
          , CA.noGrid      -- By default a grid line is added
                           -- for each tick. This removes them.

          , CA.ints            -- Add ticks at "nice" ints
          , CA.times Time.utc  -- Add ticks at "nice" times

          , CA.pinned .max  -- Change what y position the ticks are set at
                            -- .max is at the very top
                            -- .min is at the very bottom
                            -- CA.zero is the closest you can go to zero
                            -- (always 3) is at y = 3.
          , CA.limits
              [ CA.lowest 2 CA.exactly
              , CA.highest 8 CA.exactly
              ]
              -- Change the upper and lower limit of your tick range.
              -- The example will add ticks between x = 2 and 8.
          ]
      ]
-}
xTicks : List (CA.Attribute Ticks) -> Element item msg
xTicks edits =
  let config =
        Helpers.apply edits
          { color = ""
          , limits = []
          , pinned = CA.zero
          , amount = 5
          , generate = IS.Floats
          , height = 5
          , flip = False
          , grid = True
          , width = 1
          }

      toTicks p =
        List.foldl (\f x -> f x) p.x config.limits
          |> generateValues config.amount config.generate Nothing
          |> List.map .value

      addTickValues p ts =
        if not config.grid then ts else
        { ts | xs = ts.xs ++ toTicks p }
  in
  TicksElement addTickValues <| \p ->
    let toTick x =
          CS.xTick p
            [ CA.color config.color
            , CA.length (if config.flip then -config.height else config.height)
            , CA.width config.width
            ]
            { x = x
            , y = config.pinned p.y
            }
    in
    S.g [ SA.class "elm-charts__x-ticks" ] <| List.map toTick (toTicks p)


{-| Produce a set of ticks at "nice" numbers on the y-axis of your chart.
The styling options are the same as for `xTicks`.
-}
yTicks : List (CA.Attribute Ticks) -> Element item msg
yTicks edits =
  let config =
        Helpers.apply edits
          { color = ""
          , limits = []
          , pinned = CA.zero
          , amount = 5
          , generate = IS.Floats
          , height = 5
          , flip = False
          , grid = True
          , width = 1
          }

      toTicks p =
        List.foldl (\f y -> f y) p.y config.limits
          |> generateValues config.amount config.generate Nothing
          |> List.map .value

      addTickValues p ts =
        { ts | ys = ts.ys ++ toTicks p }
  in
  TicksElement addTickValues <| \p ->
    let toTick y =
          CS.yTick p
            [ CA.color config.color
            , CA.length (if config.flip then -config.height else config.height)
            , CA.width config.width
            ]
            { x = config.pinned p.x
            , y = y
            }
    in
    S.g [ SA.class "elm-charts__y-ticks" ] <| List.map toTick (toTicks p)



type alias Labels =
  { color : String
  , pinned : C.Axis -> Float
  , limits : List (CA.Attribute C.Axis)
  , xOff : Float
  , yOff : Float
  , flip : Bool
  , amount : Int
  , anchor : Maybe IS.Anchor
  , generate : IS.TickType
  , fontSize : Maybe Int
  , uppercase : Bool
  , format : Maybe (Float -> String)
  , rotate : Float
  , grid : Bool
  }


{-| Produce a set of labels at "nice" numbers on the x-axis of your chart.
The example below illustrates the configuration:

    C.chart []
      [ C.xLabels
          [ CA.color "red"  -- Change color
          , CA.fontSize 12  -- Change font size
          , CA.uppercase    -- Make labels uppercase
          , CA.rotate 90    -- Rotate labels

          , CA.alignRight   -- Anchor labels to the right
          , CA.alignLeft    -- Anchor labels to the left

          , CA.moveUp 5     -- Move 5 SVG units up
          , CA.moveDown 5   -- Move 5 SVG units down
          , CA.moveLeft 5   -- Move 5 SVG units left
          , CA.moveRight 5  -- Move 5 SVG units right

          , CA.amount 15   -- Change amount of ticks
          , CA.flip        -- Flip to opposite direction
          , CA.noGrid      -- By default a grid line is added
                           -- for each label. This removes them.

          , CA.ints            -- Add ticks at "nice" ints
          , CA.times Time.utc  -- Add ticks at "nice" times

          , CA.format (\num -> String.fromFloat num ++ "°")
              -- Format the "nice" number

          , CA.pinned .max  -- Change what y position the labels are set at
                            -- .max is at the very top
                            -- .min is at the very bottom
                            -- CA.zero is the closest you can go to zero
                            -- (always 3) is at y = 3.
          , CA.limits
              [ CA.lowest 2 CA.exactly
              , CA.highest 8 CA.exactly
              ]
              -- Change the upper and lower limit of your labels range.
              -- The example will add labels between x = 2 and 8.
          ]
      ]

For more in depth and irregular customization, see `xLabel`.

-}
xLabels : List (CA.Attribute Labels) -> Element item msg
xLabels edits =
  let toConfig p =
        Helpers.apply edits
          { color = "#808BAB"
          , limits = []
          , pinned = CA.zero
          , amount = 5
          , generate = IS.Floats
          , flip = False
          , anchor = Nothing
          , xOff = 0
          , yOff = 18
          , grid = True
          , format = Nothing
          , uppercase = False
          , rotate = 0
          , fontSize = Nothing
          }

      toTicks p config =
        List.foldl (\f x -> f x) p.x config.limits
          |> generateValues config.amount config.generate config.format

      toTickValues p config ts =
        if not config.grid then ts else
        { ts | xs = ts.xs ++ List.map .value (toTicks p config) }
  in
  LabelsElement toConfig toTickValues <| \p config ->
    let default = IS.defaultLabel
        toLabel item =
          IS.label p
            { default
            | xOff = config.xOff
            , yOff = if config.flip then -config.yOff + 10 else config.yOff
            , color = config.color
            , anchor = config.anchor
            , fontSize = config.fontSize
            , uppercase = config.uppercase
            , rotate = config.rotate
            }
            [ S.text item.label ]
            { x = item.value
            , y = config.pinned p.y
            }
    in
    S.g [ SA.class "elm-charts__x-labels" ] (List.map toLabel (toTicks p config))


{-| Produce a set of labels at "nice" numbers on the y-axis of your chart.
The styling options are the same as for `xLabels`.
-}
yLabels : List (CA.Attribute Labels) -> Element item msg
yLabels edits =
  let toConfig p =
        Helpers.apply edits
          { color = "#808BAB"
          , limits = []
          , pinned = CA.zero
          , amount = 5
          , generate = IS.Floats
          , anchor = Nothing
          , flip = False
          , xOff = -10
          , yOff = 3
          , grid = True
          , format = Nothing
          , uppercase = False
          , fontSize = Nothing
          , rotate = 0
          }

      toTicks p config =
        List.foldl (\f y -> f y) p.y config.limits
          |> generateValues config.amount config.generate config.format

      toTickValues p config ts =
        if not config.grid then ts else
        { ts | ys = ts.ys ++ List.map .value (toTicks p config) }
  in
  LabelsElement toConfig toTickValues <| \p config ->
    let default = IS.defaultLabel
        toLabel item =
          IS.label p
            { default
            | xOff = if config.flip then -config.xOff else config.xOff
            , yOff = config.yOff
            , color = config.color
            , fontSize = config.fontSize
            , uppercase = config.uppercase
            , rotate = config.rotate
            , anchor =
                case config.anchor of
                  Nothing -> Just (if config.flip then IS.Start else IS.End)
                  Just anchor -> Just anchor
            }
            [ S.text item.label ]
            { x = config.pinned p.x
            , y = item.value
            }
    in
    S.g [ SA.class "elm-charts__y-labels" ] (List.map toLabel (toTicks p config))


{-| -}
type alias Label =
  { x : Float
  , y : Float
  , xOff : Float
  , yOff : Float
  , border : String
  , borderWidth : Float
  , fontSize : Maybe Int
  , color : String
  , anchor : Maybe IS.Anchor
  , rotate : Float
  , uppercase : Bool
  , flip : Bool
  , grid : Bool
  }


{-| Produce a single x label. This is typically for cases where you need
very custom labels and `xLabels` does not cut it. It is especially useful
in combination with the `generate` helper. An example use case:

    C.chart []
      [ -- Create labels for 10 "nice" integers on the x-axis
        -- and highlight the label at x = 0.
        C.generate 10 C.ints .x [] <| \plane int ->
          let color = if int == 0 then "red" else "gray" in
          [ C.xLabel
              [ CA.x (toFloat int), CA.color color ]
              [ S.text (String.fromInt int) ]
          ]
      ]

A full list of possible attributes:

    C.chart []
      [ C.xLabel
          [ CA.x 5  -- Set x coordinate
          , CA.y 8  -- Set y coordinate

          , CA.moveUp 5     -- Move 5 SVG units up
          , CA.moveDown 5   -- Move 5 SVG units down
          , CA.moveLeft 5   -- Move 5 SVG units left
          , CA.moveRight 5  -- Move 5 SVG units right

          , CA.border "white"   -- Set stroke color
          , CA.borderWidth 0.5  -- Set stroke width

          , CA.fontSize 12      -- Set font size
          , CA.color "red"      -- Set color

          , CA.alignRight   -- Anchor labels to the right
          , CA.alignLeft    -- Anchor labels to the left

          , CA.rotate 90    -- Rotate label 90 degrees
          , CA.uppercase    -- Make uppercase
          , CA.flip         -- Flip to opposite direction

          , CA.noGrid      -- By default a grid line is added
                           -- for each label. This removes it.
          ]
          [ S.text "hello!" ]
      ]

-}
xLabel : List (CA.Attribute Label) -> List (S.Svg msg) -> Element data msg
xLabel edits inner =
  let toConfig p =
        Helpers.apply edits
          { x = CA.middle p.x
          , y = CA.zero p.y
          , xOff = 0
          , yOff = 20
          , border = "white"
          , borderWidth = 0.1
          , uppercase = False
          , fontSize = Nothing
          , color = "#808BAB"
          , anchor = Nothing
          , rotate = 0
          , flip = False
          , grid = True
          }

      toTickValues p config ts =
        if not config.grid then ts else
        { ts | xs = ts.xs ++ [ config.x ] }
  in
  LabelElement toConfig toTickValues <| \p config ->
    let string =
          if inner == []
          then [ S.text (String.fromFloat config.x) ]
          else inner
    in
    IS.label p
      { xOff = config.xOff
      , yOff = if config.flip then -config.yOff + 10 else config.yOff
      , border = config.border
      , borderWidth = config.borderWidth
      , fontSize = config.fontSize
      , uppercase = config.uppercase
      , color = config.color
      , anchor = config.anchor
      , rotate = config.rotate
      , attrs = []
      }
      string
      { x = config.x, y = config.y }


{-| Produce a single y label. This is typically for cases where you need
very custom labels and `yLabels` does not cut it. See `xLabel` for
usage and customization.

-}
yLabel : List (CA.Attribute Label) -> List (S.Svg msg) -> Element data msg
yLabel edits inner =
  let toConfig p =
        Helpers.apply edits
          { x = CA.zero p.x
          , y = CA.middle p.y
          , xOff = -8
          , yOff = 3
          , border = "white"
          , borderWidth = 0.1
          , uppercase = False
          , fontSize = Nothing
          , color = "#808BAB"
          , anchor = Nothing
          , rotate = 0
          , flip = False
          , grid = True
          }

      toTickValues p config ts =
        if not config.grid then ts else
        { ts | ys = ts.ys ++ [ config.y ] }
  in
  LabelElement toConfig toTickValues <| \p config ->
    let string =
          if inner == []
          then [ S.text (String.fromFloat config.y) ]
          else inner
    in
    IS.label p
      { xOff = if config.flip then -config.xOff else config.xOff
      , yOff = config.yOff
      , border = config.border
      , borderWidth = config.borderWidth
      , fontSize = config.fontSize
      , uppercase = config.uppercase
      , color = config.color
      , anchor =
          case config.anchor of
            Nothing -> Just (if config.flip then IS.Start else IS.End)
            Just anchor -> Just anchor
      , rotate = config.rotate
      , attrs = []
      }
      string
      { x = config.x, y = config.y }



{-| -}
type alias Tick =
  { x : Float
  , y : Float
  , color : String
  , width : Float
  , length : Float
  , flip : Bool
  , grid : Bool
  }


{-| Produce a single x tick. This is typically for cases where you need
very custom ticks and `xTicks` does not cut it. It is especially useful
in combination with the `generate` helper. An example use case:

    C.chart []
      [ -- Create ticks for 10 "nice" integers on the x-axis
        -- and highlight the tick at x = 0.
        C.generate 10 C.ints .x [] <| \plane int ->
          let color = if int == 0 then "red" else "gray" in
          [ C.xTick [ CA.x (toFloat int), CA.color color ] ]
      ]


A full list of possible attributes:

    C.xTick
      [ CA.x 5  -- Set x coordinate
      , CA.y 8  -- Set y coordinate

      , CA.color "red" -- Change color
      , CA.height 8    -- Change height
      , CA.width 2     -- Change width
      , CA.amount 15   -- Change amount of ticks
      , CA.flip        -- Flip to opposite direction
      , CA.noGrid      -- By default a grid line is added
                       -- for each tick. This removes them.
      ]

-}
xTick : List (CA.Attribute Tick) -> Element data msg
xTick edits =
  let toConfig p =
        Helpers.apply edits
          { x = CA.middle p.x
          , y = CA.zero p.y
          , length = 5
          , color = "rgb(210, 210, 210)"
          , width = 1
          , flip = False
          , grid = True
          }

      toTickValues p config ts =
        if not config.grid then ts else
        { ts | xs = ts.xs ++ [ config.x ] }
  in
  TickElement toConfig toTickValues <| \p config ->
    CS.xTick p
      [ CA.length (if config.flip then -config.length else config.length)
      , CA.color config.color
      , CA.width config.width
      ]
      { x = config.x, y = config.y }


{-| Produce a single y tick. This is typically for cases where you need
very custom ticks and `yTicks` does not cut it. See `xTick` for
usage and customization.

-}
yTick : List (CA.Attribute Tick) -> Float -> Element data msg
yTick edits val =
  let toConfig p =
        Helpers.apply edits
          { x = CA.middle p.x
          , y = CA.zero p.y
          , length = 5
          , color = "rgb(210, 210, 210)"
          , width = 1
          , flip = False
          , grid = True
          }

      toTickValues p config ts =
        if not config.grid then ts else
        { ts | ys = ts.ys ++ [ config.y ] }
  in
  TickElement toConfig toTickValues <| \p config ->
    CS.yTick p
      [ CA.length (if config.flip then -config.length else config.length)
      , CA.color config.color
      , CA.width config.width
      ]
      { x = config.x, y = config.y }



type alias Grid =
    { color : String
    , width : Float
    , dotGrid : Bool
    , dashed : List Float
    }


{-| Add a grid to your chart.

    C.chart []
      [ C.grid []
      , C.xLabels []
      , C.yLabels []
      ]

Grid lines are added where labels or ticks are added.

Customizations:

    C.grid
      [ CA.color "blue"     -- Change color
      , CA.width 3          -- Change width
      , CA.dashed [ 5, 5 ]  -- Add dashing (only for line grids)
      , CA.dotGrid          -- Use dot grid instead of line grid
      ]
-}
grid : List (CA.Attribute Grid) -> Element item msg
grid edits =
  let config =
        Helpers.apply edits
          { color = ""
          , width = 0
          , dotGrid = False
          , dashed = []
          }

      color =
        if String.isEmpty config.color then
          if config.dotGrid then Helpers.darkGray else Helpers.gray
        else
          config.color

      width =
        if config.width == 0 then
          if config.dotGrid then 0.5 else 1
        else
          config.width

      toXGrid vs p v =
        if List.member v vs.xAxis
        then Nothing else Just <|
          CS.line p [ CA.color color, CA.width width, CA.x1 v, CA.dashed config.dashed ]

      toYGrid vs p v =
        if List.member v vs.yAxis
        then Nothing else Just <|
          CS.line p [ CA.color color, CA.width width, CA.y1 v, CA.dashed config.dashed ]

      toDot vs p x y =
        if List.member x vs.xAxis || List.member y vs.yAxis
        then Nothing
        else Just <| CS.dot p .x .y [ CA.color color, CA.size width, CA.circle ] { x = x, y = y }
  in
  GridElement <| \p vs ->
    S.g [ SA.class "elm-charts__grid" ] <|
      if config.dotGrid then
        List.concatMap (\x -> List.filterMap (toDot vs p x) vs.ys) vs.xs
      else
        [ S.g [ SA.class "elm-charts__x-grid" ] (List.filterMap (toXGrid vs p) vs.xs)
        , S.g [ SA.class "elm-charts__y-grid" ] (List.filterMap (toYGrid vs p) vs.ys)
        ]



-- PROPERTIES


{-| A property of a bar, line, or scatter series.

-}
type alias Property data inter deco =
  P.Property data String inter deco


{-| Specify the configuration of a bar. The first argument will determine the height of
your bar. The second is a list of styling attributes. The example below illustrates what
styling options are available.

    C.chart []
      [ C.bars []
          [ C.bar .income
              [ CA.color "blue"      -- Change the color
              , CA.border "darkblue" -- Change the border color
              , CA.borderWidth 2     -- Change the border width
              , CA.opacity 0.7       -- Change the border opacity

              -- A bar can either be solid (default), striped, dotted, or gradient.
              , CA.striped
                  [ CA.width 2      -- Width of each stripe
                  , CA.spacing 3    -- Spacing bewteen each stripe
                  , CA.color "blue" -- Color of stripe
                  , CA.rotate 90    -- Angle of stripe
                  ]

              , CA.dotted []
                  -- Same configurations as `striped`

              , CA.gradient
                  [ "blue", "darkblue" ] -- List of colors in gradient

              , CA.roundTop 0.2    -- Round the top corners
              , CA.roundBottom 0.2 -- Round the bottom corners

              -- You can highlight a bar or a set of bars by adding a kind of "aura" to it.
              , CA.highlight 0.5          -- Determine the opacity of the aura
              , CA.highlightWidth 5       -- Determine the width of the aura
              , CA.highlightColor "blue"  -- Determine the color of the aura

              -- Add arbitrary SVG attributes to your bar
              , CA.attrs [ SA.strokeOpacity "0.5" ]
              ]
          ]
          [ { income = 10 }
          , { income = 12 }
          , { income = 18 }
          ]
      ]

-}
bar : (data -> Float) -> List (CA.Attribute CS.Bar) -> Property data inter CS.Bar
bar y =
  P.property (y >> Just) []


{-| Same as `bar`, but allows for missing data.

    C.chart []
      [ C.bars []
          [ C.barMaybe .income [] ]
          [ { income = Just 10 }
          , { income = Nothing }
          , { income = Just 18 }
          ]
      ]

-}
barMaybe : (data -> Maybe Float) -> List (CA.Attribute CS.Bar) -> Property data inter CS.Bar
barMaybe y =
  P.property y []


{-| Specify the configuration of a set of dots. The first argument will determine the y value of
your dots. The second is a list of styling attributes. The example below illustrates what styling
options are available.

    C.series .year
      [ C.scatter .income
          [ CA.size 10            -- Change size of dot
          , CA.color "blue"       -- Change color
          , CA.opacity 0.8        -- Change opacity
          , CA.border "lightblue" -- Change border color
          , CA.borderWidth 2      -- Change border width

          -- You can highlight a dot or a set of dots by adding a kind of "aura" to it.
          , CA.highlight 0.3          -- Determine the opacity of the aura
          , CA.highlightWidth 6       -- Determine the width of the aura
          , CA.highlightColor "blue"  -- Determine the color of the aura

          -- A dot is by default a circle, but you can change it to any
          -- of the shapes below.
          , CA.triangle
          , CA.square
          , CA.diamond
          , CA.plus
          , CA.cross
          ]
      ]
      [ { year = 2000, income = 40000 }
      , { year = 2010, income = 57000 }
      , { year = 2020, income = 62000 }
      ]

-}
scatter : (data -> Float) -> List (CA.Attribute CS.Dot) -> Property data inter CS.Dot
scatter y =
  P.property (y >> Just) []


{-| Same as `scatter`, but allows for missing data.

    C.chart []
      [ C.series .year
          [ C.scatterMaybe .income [] ]
          [ { year = 2000, income = Just 40000 }
          , { year = 2010, income = Nothing }
          , { year = 2020, income = Just 62000 }
          ]
      ]

-}
scatterMaybe : (data -> Maybe Float) -> List (CA.Attribute CS.Dot) -> Property data inter CS.Dot
scatterMaybe y =
  P.property y []


{-| Specify the configuration of a interpolated series (a line). The first argument will determine
the y value of your dots. The second is a list of attributes pertaining to your interpolation. The
third argument is a list of attributes pertaining to the dots of your series.

The example below illustrates what styling options are available.

    C.series .age
      [ C.interpolated .height
          [ -- The following attributes allow alternatives to the default
            -- linear interpolation.
            CA.monotone  -- Use a monotone interpolation (looks smooth)
          , CA.stepped   -- Use a stepped interpolation (looks like stairs)

          , CA.color "blue"
          , CA.width 2
          , CA.dashed [ 4, 4 ]

          -- The area beneath the curve is by default transparent, but you
          -- can change the opacity of it, or make it striped, dotted, or gradient.
          , CA.opacity 0.5

          , CA.striped
              [ CA.width 2      -- Width of each stripe
              , CA.spacing 3    -- Spacing bewteen each stripe
              , CA.color "blue" -- Color of stripe
              , CA.rotate 90    -- Angle of stripe
              ]

          , CA.dotted [] -- Same configurations as `striped`

          , CA.gradient [ "blue", "darkblue" ] -- List of colors in gradient

          -- Add arbitrary SVG attributes to your line
          , CA.attrs [ SA.id "my-chart" ]
          ]
          []
      ]
      [ { age = 0, height = 40 }
      , { age = 5, height = 80 }
      , { age = 10, height = 120 }
      , { age = 15, height = 180 }
      , { age = 20, height = 184 }
      ]

-}
interpolated : (data -> Float) -> List (CA.Attribute CS.Interpolation) -> List (CA.Attribute CS.Dot) -> Property data CS.Interpolation CS.Dot
interpolated y inter =
  P.property (y >> Just) ([ CA.linear ] ++ inter)


{-| Same as `interpolated`, but allows for missing data.

    C.chart []
      [ C.series .age
          [ C.interpolatedMaybe .height [] ]
          [ { age = 0, height = Just 40 }
          , { age = 5, height = Nothing }
          , { age = 10, height = Just 120 }
          , { age = 15, height = Just 180 }
          , { age = 20, height = Just 184 }
          ]
      ]

-}
interpolatedMaybe : (data -> Maybe Float) -> List (CA.Attribute CS.Interpolation) -> List (CA.Attribute CS.Dot) -> Property data CS.Interpolation CS.Dot
interpolatedMaybe y inter =
  P.property y ([ CA.linear ] ++ inter)


{-| Name a bar, scatter, or interpolated series. This name will show up
in the default tooltip, and you can use it to identify items from this series.

    C.chart []
      [ C.series .year
          [ C.scatter .income []
              |> C.named "Income"
          ]
          [ { year = 2000, income = 40000 }
          , { year = 2010, income = 48000 }
          , { year = 2020, income = 62000 }
          ]
      ]

-}
named : String -> Property data inter deco -> Property data inter deco
named name =
  P.meta name


{-| Change the style of your bars or dots based on the index of its data point
and the data point itself.

    C.chart []
      [ C.series .year
          [ C.scatter .income [ CA.opacity 0.6 ]
              |> C.variation (\index datum -> [ CA.size datum.people ])
          ]
          [ { year = 2000, income = 40000, people = 150 }
          , { year = 2010, income = 48000, people = 98 }
          , { year = 2020, income = 62000, people = 180 }
          ]
      ]

-}
variation : (Int -> data -> List (CA.Attribute deco)) -> Property data inter deco -> Property data inter deco
variation func =
  P.variation <| \_ _ index _ datum -> func index datum


{-| Change the style of your bars or dots based on whether it is a member
of the group of products which you list. A such group of products can be
attrained through events like `Chart.Events.onMouseMove` or similar.

    C.chart
      [ CE.onMouseMove OnHover (CE.getNearest CE.dot) ]
      [ C.series .year
          [ C.scatter .income [ CA.opacity 0.6 ]
              |> C.amongst model.hovering (\datum -> [ CA.highlight 0.5 ])
          ]
          [ { year = 2000, income = 40000, people = 150 }
          , { year = 2010, income = 48000, people = 98 }
          , { year = 2020, income = 62000, people = 180 }
          ]
      ]

-}
amongst : List (CE.Product config value data) -> (data -> List (CA.Attribute deco)) -> Property data inter deco -> Property data inter deco
amongst inQuestion func =
  P.variation <| \p s i meta d ->
    let check product =
          if Item.getPropertyIndex product == p &&
             Item.getStackIndex product == s &&
             Item.getDataIndex product == i &&
             Item.getDatum product == d
          then func d else []
    in
    List.concatMap check inQuestion


{-| Stack a set of bar or line series.

    C.chart []
      [ C.bars []
          [ C.stacked
              [ C.bar .cats []
              , C.bar .dogs []
              ]
          ]
          [ { cats = 2, dogs = 4 }
          , { cats = 3, dogs = 2 }
          , { cats = 6, dogs = 1 }
          ]
      ]
-}
stacked : List (Property data inter deco) -> Property data inter deco
stacked =
  P.stacked



-- LABEL EXTRAS


{-| Add labels by every bin.

    C.chart []
      [ C.bars [] [ C.bar .income [] ]
          [ { name = "Anna", income = 60 }
          , { name = "Karenina", income = 70 }
          , { name = "Jane", income = 80 }
          ]

      , C.binLabels .name CE.getBottom [ CA.moveDown 15 ]
      ]

Attributes you can use:

    C.binLabels .name CE.getBottom
      [ CA.moveUp 5     -- Move 5 SVG units up
      , CA.moveDown 5   -- Move 5 SVG units down
      , CA.moveLeft 5   -- Move 5 SVG units left
      , CA.moveRight 5  -- Move 5 SVG units right

      , CA.color "#333"
      , CA.border "white"
      , CA.borderWidth 1
      , CA.fontSize 12

      , CA.alignRight   -- Anchor labels to the right
      , CA.alignLeft    -- Anchor labels to the left

      , CA.rotate 90    -- Rotate label 90 degrees
      , CA.uppercase    -- Make uppercase

       -- Add arbitrary SVG attributes to your labels.
      , CA.attrs [ SA.class "my-bin-labels" ]
      ]

-}
binLabels : (data -> String) -> (CS.Plane -> CE.Group (CE.Bin data) CE.Bar (Maybe Float) data -> CS.Point) -> List (CA.Attribute CS.Label) -> Element data msg
binLabels toLabel toPosition labelAttrs =
  -- TODO make even nicer api
  eachCustom (CE.collect CE.bin CE.bar) <| \p item ->
    [ label labelAttrs [ S.text (toLabel (CE.getCommonality item).datum) ] (toPosition p item) ]


{-| Add labels by every bar.

    C.chart []
      [ C.bars []
          [ C.bar .income [] ]
          [ { name = "Anna", income = 60 }
          , { name = "Karenina", income = 70 }
          , { name = "Jane", income = 80 }
          ]

      , C.barLabels CE.getTop [ CA.moveUp 6 ]
      ]

Attributes you can use:

    C.barLabels CE.getTop
      [ CA.moveUp 5     -- Move 5 SVG units up
      , CA.moveDown 5   -- Move 5 SVG units down
      , CA.moveLeft 5   -- Move 5 SVG units left
      , CA.moveRight 5  -- Move 5 SVG units right

      , CA.color "#333"
      , CA.border "white"
      , CA.borderWidth 1
      , CA.fontSize 12

      , CA.alignRight   -- Anchor labels to the right
      , CA.alignLeft    -- Anchor labels to the left

      , CA.rotate 90    -- Rotate label 90 degrees
      , CA.uppercase    -- Make uppercase

       -- Add arbitrary SVG attributes to your labels.
      , CA.attrs [ SA.class "my-bar-labels" ]
      ]
-}
barLabels : (CS.Plane -> CE.Product CE.Bar Float data -> CS.Point) -> List (CA.Attribute CS.Label) -> Element data msg
barLabels toPosition labelAttrs =
  eachBar <| \p item ->
    [ label labelAttrs [ S.text (String.fromFloat (CE.getDependent item)) ] (toPosition p item) ]


{-| Add labels by every bar.

    C.chart []
      [ C.series .age
          [ C.scatter .income [] ]
          [ { age = 34, income = 60 }
          , { age = 42, income = 70 }
          , { age = 48, income = 80 }
          ]

      , C.dotLabels CE.getCenter [ CA.moveUp 6 ]
      ]

Attributes you can use:

    C.dotLabels CE.getCenter
      [ CA.moveUp 5     -- Move 5 SVG units up
      , CA.moveDown 5   -- Move 5 SVG units down
      , CA.moveLeft 5   -- Move 5 SVG units left
      , CA.moveRight 5  -- Move 5 SVG units right

      , CA.color "#333"
      , CA.border "white"
      , CA.borderWidth 1
      , CA.fontSize 12

      , CA.alignRight   -- Anchor labels to the right
      , CA.alignLeft    -- Anchor labels to the left

      , CA.rotate 90    -- Rotate label 90 degrees
      , CA.uppercase    -- Make uppercase

       -- Add arbitrary SVG attributes to your labels.
      , CA.attrs [ SA.class "my-dot-labels" ]
      ]
-}
dotLabels : (CS.Plane -> CE.Product CE.Dot Float data -> CS.Point) -> List (CA.Attribute CS.Label) -> Element data msg
dotLabels toPosition labelAttrs =
  eachDot <| \p item ->
    [ label labelAttrs [ S.text (String.fromFloat (CE.getDependent item)) ] (toPosition p item) ]



-- BARS


{-| -}
type alias Bars data =
  { spacing : Float
  , margin : Float
  , roundTop : Float
  , roundBottom : Float
  , grouped : Bool
  , grid : Bool
  , x1 : Maybe (data -> Float)
  , x2 : Maybe (data -> Float)
  }


{-| Add a bar series to your chart. Each `data` in your `List data` is a "bin". For
each "bin", whatever number of bars your have specified in the second argument will
show up, side-by-side.

    C.bars []
      [ C.bar .income []
      , C.bar .spending []
      ]
      [ { income = 10, spending = 2 }
      , { income = 12, spending = 6 }
      , { income = 18, spending = 16 }
      ]

The example above will thus produce three bins, each containing two bars. You can make
your bars show up overlapping instead of side-by-side by using the `CA.ungroup`
attribute:

    C.bars
      [ CA.ungroup ]
      [ C.bar .total []
      , C.bar .gross []
      , C.bar .net []
      ]
      [ { net = 10, gross = 20, total = 50 }
      , { net = 13, gross = 28, total = 63 }
      , { net = 16, gross = 21, total = 82 }
      ]

By default, the x value of each bin is set by a simple count. The first bin is set at
x = 1, the second at x = 2, and so on. If you'd like to control what the x values of
your bins are, e.g. you are making a histogram, you may use the `CA.x1` and `CA.x2`
attributes, as illustrated below.

    C.bars
      [ CA.x1 .score
      , CA.x2 (\datum -> datum.score + 20)
      ]
      [ C.bar .students [] ]
      [ { score = 0, students = 1 }
      , { score = 20, students = 10 }
      , { score = 40, students = 30 }
      , { score = 60, students = 20 }
      , { score = 80, students = 1 }
      ]

In this case, you actually only need to specify either `x1` or `x2` because the library
estimates the unknown x value based on the size of the previous or next bin. However, it comes in
handy to specify both when you have bins of irregular sizes.

The rest of the configuration options concern styling:

    C.bars
      [ CA.spacing 0.1      -- The spacing _between_ the bars in each bin relative to the full length (1).
      , CA.margin 0.2       -- The spacing _around_ the bars in each bin relative to the full length (1).
      , CA.roundTop 0.2     -- The rounding of your bars top corners. It gets weird after around 0.5.
      , CA.roundBottom 0.2  -- The rounding of your bars top corners. It gets weird after around 0.5.
      , CA.noGrid           -- Grid lines are by default added at the bin limits. This removes them.
      ]
      [ C.bar .income []
      , C.bar .spending []
      ]
      [ { income = 10, spending = 2 }
      , { income = 12, spending = 6 }
      , { income = 18, spending = 16 }
      ]
-}
bars : List (CA.Attribute (Bars data)) -> List (Property data () CS.Bar) -> List data -> Element data msg
bars edits properties data =
  barsMap identity edits properties data


{-| This is just like `bars`, but it maps your `data`. This is useful if you have
several kinds of data types present in your chart.

    type Datum
      = Money  { year : Float, income : Float }
      | People { year : Float, people : Float }

    view : Html msg
    view =
      C.chart []
        [ C.barsMap Money
            [ CA.x1 .year ]
            [ C.bar .income [] ]
            [ { year = 2000, income = 200 }
            , { year = 2010, income = 300 }
            , { year = 2020, income = 500 }
            ]

        , C.barsMap People
            [ CA.x1 .year ]
            [ C.bar .people [] ]
            [ { year = 2000, people = 21 }
            , { year = 2010, people = 65 }
            , { year = 2020, people = 93 }
            ]
        ]

-}
barsMap : (data -> a) -> List (CA.Attribute (Bars data)) -> List (Property data () CS.Bar) -> List data -> Element a msg
barsMap mapData edits properties data =
  Indexed <| \index ->
    let barsConfig =
          Helpers.apply edits Produce.defaultBars

        items =
          Produce.toBarSeries index edits properties data

        generalized =
          List.concatMap Group.getProducts items
            |> List.map (Item.map mapData)

        bins =
          CE.group CE.bin generalized

        legends_ =
          Legend.toBarLegends index edits properties

        toTicks plane acc =
          { acc | xs = acc.xs ++
              if barsConfig.grid then
                List.concatMap (CE.getLimits >> \pos -> [ pos.x1, pos.x2 ]) bins
              else
                []
          }

        toLimits =
          List.map Item.getLimits bins
    in
    ( BarsElement toLimits generalized legends_ toTicks <| \plane ->
        S.g [ SA.class "elm-charts__bar-series" ] (List.map (Item.toSvg plane) items)
          |> S.map never
    , index + List.length (List.concatMap P.toConfigs properties)
    )



-- SERIES


{-| Add a scatter or line series to your chart. Each `data` in your `List data` will result in one "dot".
The first argument of `series` determines the x value of each dot. The y value and all styling configuration
is determined by the list of `interpolated` or `scatter` properties defined in the second argument.

    C.series .age
      [ C.interpolated .height [] []
      , C.interpolated .weight [] []
      ]
      [ { age = 0, height = 40, weight = 4 }
      , { age = 5, height = 80, weight = 24 }
      , { age = 10, height = 120, weight = 36 }
      , { age = 15, height = 180, weight = 54 }
      , { age = 20, height = 184, weight = 60 }
      ]

See `interpolated` and `scatter` for styling options.

-}
series : (data -> Float) -> List (Property data CS.Interpolation CS.Dot) -> List data -> Element data msg
series toX properties data =
  seriesMap identity toX properties data


{-| This is just like `series`, but it maps your `data`. This is useful if you have
several kinds of data types present in your chart.

    type Datum
      = Height { age : Float, height : Float }
      | Weight { age : Float, weight : Float }

    view : Html msg
    view =
      C.chart []
        [ C.seriesMap Height .age
            [ C.interpolated .height [] ]
            [ { age = 0, height = 40 }
            , { age = 5, height = 80 }
            , { age = 10, height = 120 }
            , { age = 15, height = 180 }
            ]

        , C.seriesMap Weight .age
            [ C.interpolated .weight [] ]
            [ { age = 0, weight = 4 }
            , { age = 5, weight = 24 }
            , { age = 10, weight = 36 }
            , { age = 15, weight = 54 }
            ]
        ]

-}
seriesMap : (data -> a) -> (data -> Float) -> List (Property data CS.Interpolation CS.Dot) -> List data -> Element a msg
seriesMap mapData toX properties data =
  Indexed <| \index ->
    let items =
          Produce.toDotSeries index toX properties data

        generalized =
          List.concatMap Group.getProducts items
            |> List.map (Item.map mapData)

        legends_ =
          Legend.toDotLegends index properties

        toLimits =
          List.map Item.getLimits items
    in
    ( SeriesElement toLimits generalized legends_ <| \p ->
        S.g [ SA.class "elm-charts__dot-series" ] (List.map (Item.toSvg p) items)
          |> S.map never
    , index + List.length (List.concatMap P.toConfigs properties)
    )



-- OTHER


{-| Using the information about your coordinate system, add a list
of elements.

-}
withPlane : (C.Plane -> List (Element data msg)) -> Element data msg
withPlane func =
  SubElements <| \p is -> func p


{-| Given all your bins, add a list of elements.
Use helpers in `Chart.Events` to interact with bins.

-}
withBins : (C.Plane -> List (CE.Group (CE.Bin data) CE.Any (Maybe Float) data) -> List (Element data msg)) -> Element data msg
withBins func =
  SubElements <| \p is -> func p (CE.group CE.bin is)


{-| Given all your stacks, add a list of elements.
Use helpers in `Chart.Events` to interact with stacks.

-}
withStacks : (C.Plane -> List (CE.Group (CE.Stack data) CE.Any (Maybe Float) data) -> List (Element data msg)) -> Element data msg
withStacks func =
  SubElements <| \p is -> func p (CE.group CE.stack is)


{-| Given all your bars, add a list of elements.
Use helpers in `Chart.Events` to interact with bars.

-}
withBars : (C.Plane -> List (CE.Product CE.Bar (Maybe Float) data) -> List (Element data msg)) -> Element data msg
withBars func =
  SubElements <| \p is -> func p (CE.group CE.bar is)


{-| Given all your dots, add a list of elements.
Use helpers in `Chart.Events` to interact with dots.

-}
withDots : (C.Plane -> List (CE.Product CE.Dot (Maybe Float) data) -> List (Element data msg)) -> Element data msg
withDots func =
  SubElements <| \p is -> func p (CE.group CE.dot is)


{-| Given all your products, add a list of elements.
Use helpers in `Chart.Events` to interact with products.

-}
withProducts : (C.Plane -> List (CE.Product CE.Any (Maybe Float) data) -> List (Element data msg)) -> Element data msg
withProducts func =
  SubElements <| \p is -> func p is


{-| Add elements for each item of whatever list in the first argument.

    C.chart
      [ CE.onMouseMove OnHover (CE.getNearest CE.product) ]
      [ C.series .year
          [ C.scatter .income [] ]
          [ { year = 2000, income = 40000 }
          , { year = 2010, income = 56000 }
          , { year = 2020, income = 62000 }
          ]

      , C.each model.hovering <| \plane product ->
          [ C.tooltip product [] [] [] ]
      ]

-}
each : List a -> (C.Plane -> a -> List (Element data msg)) -> Element data msg
each items func =
  SubElements <| \p _ -> List.concatMap (func p) items


{-| Add elements for each bin.

    C.chart []
      [ C.bars []
          [ C.bar .income []
          , C.bar .spending []
          ]
          [ { country = "Denmark", income = 40000, spending = 10000 }
          , { country = "Sweden", income = 56000, spending = 12000 }
          , { country = "Norway", income = 62000, spending = 18000 }
          ]

      , C.eachBin <| \plane bin ->
          let common = CE.getCommonality bin in
          [ C.label [] [ S.text common.datum.country ] (CE.getBottom plane bin) ]
      ]

Use the functions in `Chart.Events` to access information about your bins.

-}
eachBin : (C.Plane -> CE.Group (CE.Bin data) CE.Any Float data -> List (Element data msg)) -> Element data msg
eachBin func =
  SubElements <| \p is -> List.concatMap (func p) (CE.group (CE.collect CE.bin <| CE.keep CE.realValues CE.product) is)


{-| Add elements for each stack.

    C.chart []
      [ C.bars []
          [ C.stacked
              [ C.bar .income []
              , C.bar .savings []
              ]
          ]
          [ { income = 40000, savings = 10000 }
          , { income = 56000, savings = 12000 }
          , { income = 62000, savings = 18000 }
          ]

      , C.eachStack <| \plane stack ->
          let total = List.sum (List.map CE.getDependent (CE.getProducts stack)) in
          [ C.label [] [ S.text (String.fromFloat total) ] (CE.getTop plane stack) ]
      ]

Use the functions in `Chart.Events` to access information about your stacks.

-}
eachStack : (C.Plane -> CE.Group (CE.Stack data) CE.Any Float data -> List (Element data msg)) -> Element data msg
eachStack func =
  SubElements <| \p is -> List.concatMap (func p) (CE.group (CE.collect CE.stack <| CE.keep CE.realValues CE.product) is)


{-| Add elements for each bar.

    C.chart []
      [ C.bars []
          [ C.bar .income []
          , C.bar .spending []
          ]
          [ { income = 40000, spending = 10000 }
          , { income = 56000, spending = 12000 }
          , { income = 62000, spending = 18000 }
          ]

      , C.eachBar <| \plane bar ->
          let yValue = CE.getDependent bar in
          [ C.label [] [ S.text (String.fromFloat yValue) ] (CE.getTop plane bar) ]
      ]

Use the functions in `Chart.Events` to access information about your bars.

-}
eachBar : (C.Plane -> CE.Product CE.Bar Float data -> List (Element data msg)) -> Element data msg
eachBar func =
  SubElements <| \p is -> List.concatMap (func p) (CE.group (CE.keep CE.realValues CE.bar) is)


{-| Add elements for each dot.

    C.chart []
      [ C.series []
          [ C.scatter .income []
          , C.scatter .spending []
          ]
          [ { income = 40000, spending = 10000 }
          , { income = 56000, spending = 12000 }
          , { income = 62000, spending = 18000 }
          ]

      , C.eachBar <| \plane bar ->
          let yValue = CE.getDependent bar in
          [ C.label [] [ S.text (String.fromFloat yValue) ] (CE.getTop plane bar) ]
      ]

Use the functions in `Chart.Events` to access information about your dots.

-}
eachDot : (C.Plane -> CE.Product CE.Dot Float data -> List (Element data msg)) -> Element data msg
eachDot func =
  SubElements <| \p is -> List.concatMap (func p) (CE.group (CE.keep CE.realValues CE.dot) is)


{-| Add elements for each product. Works like `eachBar` and `eachDot`, but includes both
bars and dots.

Use the functions in `Chart.Events` to access information about your products.

-}
eachProduct : (C.Plane -> CE.Product CE.Any Float data -> List (Element data msg)) -> Element data msg
eachProduct func =
  SubElements <| \p is -> List.concatMap (func p) (CE.group (CE.keep CE.realValues CE.product) is)


{-| Filter and group products in any way you'd like and add elements for each of them.

    C.chart []
      [ C.eachCustom (CE.named "cats") <| \plane product ->
          [ C.label [] [ S.text "hello" ] (CE.getTop plane product) ]
      ]

The above example adds a label for each product of the series named "cats".

Use the functions in `Chart.Events` to access information about your items.

-}
eachCustom : CE.Grouping (CE.Product CE.Any (Maybe Float) data) a -> (C.Plane -> a -> List (Element data msg)) -> Element data msg
eachCustom grouping func =
  SubElements <| \p items ->
    let processed = CE.group grouping items in
    List.concatMap (func p) processed


{-| Add legends to your chart.

    C.chart []
      [ C.series .x
          [ C.line .y [] []
              |> C.named "cats"
          , C.line .y [] []
              |> C.named "dogs"
          ]

      , C.legendsAt .min .max
          [ CA.column       -- Appear as column instead of row
          , CA.alignRight   -- Anchor legends to the right
          , CA.alignLeft    -- Anchor legends to the left

          , CA.moveUp 5     -- Move 5px up
          , CA.moveDown 5   -- Move 5px down
          , CA.moveLeft 5   -- Move 5px left
          , CA.moveRight 5  -- Move 5px right

          , CA.spacing 20         -- Spacing between legends
          , CA.background "beige" -- Color background
          , CA.border "gray"      -- Add border
          , CA.borderWidth 1      -- Set border width

            -- Add arbitrary HTML attributes. Convinient for extra styling.
          , CA.htmlAttrs [ HA.class "my-legend" ]
          ]
          [ CA.width 30    -- Change width of legend window
          , CA.height 30   -- Change height of legend window
          , CA.fontSize 12 -- Change font size
          , CA.color "red" -- Change font color
          , CA.spacing 12  -- Change spacing between window and title

          , CA.htmlAttrs [ HA.class "my-legends" ] -- Add arbitrary HTML attributes.
          ]
      ]
-}
legendsAt : (C.Axis -> Float) -> (C.Axis -> Float) -> List (CA.Attribute (CS.Legends msg)) -> List (CA.Attribute (CS.Legend msg)) -> Element data msg
legendsAt toX toY attrs children =
  HtmlElement <| \p legends_ ->
    let viewLegend legend =
          case legend of
            Legend.BarLegend name barAttrs -> CS.barLegend (CA.title name :: children) barAttrs
            Legend.LineLegend name interAttrs dotAttrs -> CS.lineLegend (CA.title name :: children) interAttrs dotAttrs
    in
    CS.legendsAt p (toX p.x) (toY p.y) attrs (List.map viewLegend legends_)


{-| Generate "nice" numbers. Useful in combination with `xLabel`, `yLabel`, `xTick`, and `yTick`.

    C.chart []
      [ C.generate 10 C.ints .x [ CA.lowest -5 CA.exactly, CA.highest 15 CA.exactly ] <| \plane int ->
          [ C.xTick [ CA.x (toFloat int) ]
          , C.xLabel [ CA.x (toFloat int) ] [ S.text (String.fromInt int) ]
          ]
      ]

The example above generates 10 ints on the x axis between x = -5 and x = 15. For each of those
ints, it adds a tick and a label.

-}
generate : Int -> CS.Generator a -> (C.Plane -> C.Axis) -> List (CA.Attribute C.Axis) -> (C.Plane -> a -> List (Element data msg)) -> Element data msg
generate num gen limit attrs func =
  SubElements <| \p _ ->
    let items = CS.generate num gen (List.foldl (\f x -> f x) (limit p) attrs) in
    List.concatMap (func p) items


{-| Generate "nice" floats.
-}
floats : CS.Generator Float
floats =
  CS.floats


{-| Generate "nice" ints.
-}
ints : CS.Generator Int
ints =
  CS.ints


{-| Generate "nice" times.

See the docs in [terezka/intervals](https://package.elm-lang.org/packages/terezka/intervals/2.0.0/Intervals#Time)
for more info about the properties of `Time`!

-}
times : Time.Zone -> CS.Generator I.Time
times =
  CS.times


{-| Add a label, such as a chart title or other note, at a specific coordinate.

    C.chart []
      [ C.label [] [ S.text "Data from Fruits.com" ] { x = 5, y = 10 } ]

The example above adds your label at coordinates x = y and y = 10.

Other attributes you can use:

    C.labelAt
      [ CA.moveUp 5     -- Move 5 SVG units up
      , CA.moveDown 5   -- Move 5 SVG units down
      , CA.moveLeft 5   -- Move 5 SVG units left
      , CA.moveRight 5  -- Move 5 SVG units right

      , CA.color "#333"
      , CA.border "white"
      , CA.borderWidth 1
      , CA.fontSize 12

      , CA.alignRight   -- Anchor labels to the right
      , CA.alignLeft    -- Anchor labels to the left

      , CA.rotate 90    -- Rotate label 90 degrees
      , CA.uppercase    -- Make uppercase

       -- Add arbitrary SVG attributes to your labels.
      , CA.attrs [ SA.class "my-label" ]
      ]
      [ S.text "Data from Fruits.com" ]
      { x = 5, y = 10 }

-}
label : List (CA.Attribute CS.Label) -> List (S.Svg msg) -> C.Point -> Element data msg
label attrs inner point =
  SvgElement <| \p -> CS.label p attrs inner point


{-| Add a label, such as a chart title or other note, at a position relative to your axes.

    C.chart []
      [ C.labelAt (CA.percent 20) (CA.percent 90) [] [ S.text "Data from Fruits.com" ] ]

The example above adds your label at 20% the length of your range and 90% of your domain.

Other attributes you can use:

    C.labelAt (CA.percent 20) (CA.percent 90)
      [ CA.moveUp 5     -- Move 5 SVG units up
      , CA.moveDown 5   -- Move 5 SVG units down
      , CA.moveLeft 5   -- Move 5 SVG units left
      , CA.moveRight 5  -- Move 5 SVG units right

      , CA.color "#333"
      , CA.border "white"
      , CA.borderWidth 1
      , CA.fontSize 12

      , CA.alignRight   -- Anchor labels to the right
      , CA.alignLeft    -- Anchor labels to the left

      , CA.rotate 90    -- Rotate label 90 degrees
      , CA.uppercase    -- Make uppercase

       -- Add arbitrary SVG attributes to your labels.
      , CA.attrs [ SA.class "my-label" ]
      ]
      [ S.text "Data from Fruits.com" ]

-}
labelAt : (C.Axis -> Float) -> (C.Axis -> Float) -> List (CA.Attribute CS.Label) -> List (S.Svg msg) -> Element data msg
labelAt toX toY attrs inner =
  SvgElement <| \p -> CS.label p attrs inner { x = toX p.x, y = toY p.y }


{-| Add a line.

    C.chart []
      [ C.line
          [ CA.x1 2 -- Set x1
          , CA.x2 8 -- Set x2
          , CA.y1 3 -- Set y1
          , CA.y2 7 -- Set y2

            -- Instead of specifying x2 and y2
            -- you can use `xOff` and `yOff`
            -- to specify the end coordinate in
            -- terms of SVG units.
            --
            -- Useful if making little label pointers.
          , CA.xOff 30
          , CA.yOff 30

          , CA.break            -- "break" line, so it it has a 90° angle
          , CA.color "red"      -- Change color
          , CA.width 2          -- Change width
          , CA.opacity 0.8      -- Change opacity
          , CA.dashed [ 5, 5 ]  -- Add dashing

            -- Add arbitrary SVG attributes.
          , CA.attrs [ SA.id "my-line" ]
          ]
      ]

-}
line : List (CA.Attribute CS.Line) -> Element data msg
line attrs =
  SvgElement <| \p -> CS.line p attrs


{-| Add a rectangle.

    C.chart []
      [ C.rect
          [ CA.x1 2 -- Set x1
          , CA.x2 8 -- Set x2
          , CA.y1 3 -- Set y1
          , CA.y2 7 -- Set y2

          , CA.color "#aaa"     -- Change fill color
          , CA.opacity 0.8      -- Change fill opacity
          , CA.border "#333"    -- Change border color
          , CA.borderWidth 2    -- Change border width

            -- Add arbitrary SVG attributes.
          , CA.attrs [ SA.id "my-rect" ]
          ]
      ]

-}
rect : List (CA.Attribute CS.Rect) -> Element data msg
rect attrs =
  SvgElement <| \p -> CS.rect p attrs


{-| Add arbitrary SVG. See `Chart.Svg` for handy SVG helpers.

-}
svg : (C.Plane -> S.Svg msg) -> Element data msg
svg func =
  SvgElement <| \p -> func p


{-| Add arbitrary HTML.

-}
html : (C.Plane -> H.Html msg) -> Element data msg
html func =
  HtmlElement <| \p _ -> func p


{-| Add arbitrary SVG at a specific location. See `Chart.Svg` for handy SVG helpers.

    C.chart []
      [ C.svgAt .min .max 10 20 [ .. ]
          -- Add .. at x = the minumum value of your range (x-axis) + 12 SVG units
          -- and y = the maximum value of your domain (y-axis) + 20 SVG units
      ]

-}
svgAt : (C.Axis -> Float) -> (C.Axis -> Float) -> Float -> Float -> List (S.Svg msg) -> Element data msg
svgAt toX toY xOff yOff view =
  SvgElement <| \p ->
    S.g [ CS.position p 0 (toX p.x) (toY p.y) xOff yOff ] view


{-| Add arbitrary HTML at a specific location.

-}
htmlAt : (C.Axis -> Float) -> (C.Axis -> Float) -> Float -> Float -> List (H.Attribute msg) -> List (H.Html msg) -> Element data msg
htmlAt toX toY xOff yOff att view =
  HtmlElement <| \p _ ->
    CS.positionHtml p (toX p.x) (toY p.y) xOff yOff att view


{-| No element.
-}
none : Element data msg
none =
  HtmlElement <| \_ _ -> H.text ""



-- DATA HELPERS


{-| Gather data points into bins. Arguments:

1. The desired bin width.
2. The function to access the binned quality on the data
3. The list of data.


    C.binned 10 .score
      [ Result "Anna" 43
      , Result "Maya" 65
      , Result "Joan" 69
      , Result "Tina" 98
      ]
      == [ { bin = 40, data = [ Result "Anna" 43 ] }
         , { bin = 60, data = [ Result "Maya" 65, Result "Joan" 69 ] }
         , { bin = 90, data = [ Result "Tina" 98 ] }
         ]

    type alias Result = { name : String, score : Float }

-}
binned : Float -> (data -> Float) -> List data -> List { bin : Float, data : List data }
binned binWidth func data =
  let fold datum =
        Dict.update (toBin datum) (updateDict datum)

      updateDict datum maybePrev =
        case maybePrev of
          Just prev -> Just (datum :: prev)
          Nothing -> Just [ datum ]

      toBin datum =
        floor (func datum / binWidth)
  in
  List.foldr fold Dict.empty data
    |> Dict.toList
    |> List.map (\( bin, ds ) -> { bin = toFloat bin * binWidth, data = ds })



-- HELPERS



type alias TickValue =
  { value : Float
  , label : String
  }


generateValues : Int -> IS.TickType -> Maybe (Float -> String) -> C.Axis -> List TickValue
generateValues amount tick maybeFormat axis =
  let toTickValues toValue toString =
        List.map <| \i ->
            { value = toValue i
            , label =
                case maybeFormat of
                  Just format -> format (toValue i)
                  Nothing -> toString i
            }
  in
  case tick of
    IS.Floats ->
      toTickValues identity String.fromFloat
        (CS.generate amount CS.floats axis)

    IS.Ints ->
      toTickValues toFloat String.fromInt
        (CS.generate amount CS.ints axis)

    IS.Times zone ->
      toTickValues (toFloat << Time.posixToMillis << .timestamp) (CS.formatTime zone)
        (CS.generate amount (CS.times zone) axis)


