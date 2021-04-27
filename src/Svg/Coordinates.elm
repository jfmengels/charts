module Svg.Coordinates
  exposing
    ( Plane, Axis, minimum, maximum
    , scaleSVGX, scaleSVGY
    , toSVGX, toSVGY
    , scaleCartesianX, scaleCartesianY
    , toCartesianX, toCartesianY
    , place, placeWithOffset
    , Point, Position
    )

{-| This module contains helpers for cartesian/SVG coordinate translation.

# Plane
@docs Plane, Axis

# Plane from data

You may want to produce a plane which fits all your data. For that you need
to find the minimum and maximum values withing your data in order to calculate
the domain and range.

@docs minimum, maximum

    planeFromPoints : List Point -> Plane
    planeFromPoints points =
      { x =
        { marginLower = 10
        , marginUpper = 10
        , length = 300
        , min = minimum .x points
        , max = maximum .x points
        }
      , y =
        { marginLower = 10
        , marginUpper = 10
        , length = 300
        , min = minimum .y points
        , max = maximum .y points
        }
      }

# Cartesian to SVG
@docs toSVGX, toSVGY, scaleSVG

# SVG to cartesian
@docs toCartesianX, toCartesianY, scaleCartesian

# Helpers
@docs place, placeWithOffset

-}

import Svg exposing (Attribute)
import Svg.Attributes exposing (transform)



type alias Point =
  { x : Float
  , y : Float
  }


type alias Position =
  { x1 : Float
  , x2 : Float
  , y1 : Float
  , y2 : Float
  }


type alias Bounds =
  { dataMin : Float
  , dataMax : Float
  , min : Float
  , max : Float
  }



-- Plane


{-| The properties of your plane.
-}
type alias Plane =
  { x : Axis
  , y : Axis
  }


{-| The axis of the plane.

  - The margin properties are the upper and lower margins for the axis. So for example,
    if you want to add margin on top of the plot, increase the marginUpper of
    the y-`Axis`.
  - The length is the length of your SVG axis. (`plane.x.length` is the width,
    `plane.y.length` is the height)
  - The `min` and `max` values is the reach of your plane. (Domain for the y-axis, range
    for the x-axis)
-}
type alias Axis =
  { marginLower : Float
  , marginUpper : Float
  , length : Float
  , data :
      { min : Float
      , max : Float
      }
  , min : Float
  , max : Float
  }


{-| Helper to extract the minimum value amongst your coordinates.
-}
minimum : List (a -> Maybe Float) -> List a -> Float
minimum toValues =
  let fold datum toValue all =
        case toValue datum of
          Just v -> v :: all
          Nothing -> all

      eachDatum datum = List.foldl (fold datum) [] toValues
  in
  List.concatMap eachDatum
    >> List.minimum
    >> Maybe.withDefault 0


{-| Helper to extract the maximum value amongst your coordinates.
-}
maximum : List (a -> Maybe Float) -> List a -> Float
maximum toValues =
  let fold datum toValue all =
        case toValue datum of
          Just v -> v :: all
          Nothing -> all

      eachDatum datum = List.foldl (fold datum) [] toValues
  in
  List.concatMap eachDatum
    >> List.maximum
    >> Maybe.withDefault 1



-- TRANSLATION


{-| For scaling a cartesian value to a SVG value. Note that this will _not_
  return a coordinate on the plane, but the scaled value.
-}
scaleSVGX : Plane -> Float -> Float
scaleSVGX plane value =
  value * (innerLength plane.x) / (range plane.x)


scaleSVGY : Plane -> Float -> Float
scaleSVGY plane value =
  value * (innerLength plane.y) / (range plane.y)


{-| Translate a SVG x-coordinate to its cartesian x-coordinate.
-}
toSVGX : Plane -> Float -> Float
toSVGX plane value =
  scaleSVGX plane (value - plane.x.min) + plane.x.marginLower


{-| Translate a SVG y-coordinate to its cartesian y-coordinate.
-}
toSVGY : Plane -> Float -> Float
toSVGY plane value =
  scaleSVGY plane (plane.y.max - value) + plane.y.marginUpper


{-| For scaling a SVG value to a cartesian value. Note that this will _not_
  return a coordinate on the plane, but the scaled value.
-}
scaleCartesianX : Plane -> Float -> Float
scaleCartesianX plane value =
  value * (range plane.x) / (innerLength plane.x)


scaleCartesianY : Plane -> Float -> Float
scaleCartesianY plane value =
  value * (range plane.y) / (innerLength plane.y)


{-| Translate a cartesian x-coordinate to its SVG x-coordinate.
-}
toCartesianX : Plane -> Float -> Float
toCartesianX plane value =
  scaleCartesianX plane (value - plane.x.marginLower) + plane.x.min


{-| Translate a cartesian y-coordinate to its SVG y-coordinate.
-}
toCartesianY : Plane -> Float -> Float
toCartesianY plane value =
  range plane.y - scaleCartesianY plane (value - plane.y.marginUpper) + plane.y.min



-- PLACING HELPERS


{-| A `transform translate(x, y)` SVG attribute. Beware that using this and
  and another transform attribute on the same node, will overwrite the first.
  If that's the case, just make one yourself:

    myTransformAttribute : Svg.Attribute msg
    myTransformAttribute =
      transform <|
        "translate("
        ++ String.fromFloat (toSVGX plane x) ++ ","
        ++ String.fromFloat (toSVGY plane y) ++ ") "
        ++ "rotateX(" ++ whatever ++ ")"
-}
place : Plane -> Float -> Float -> Attribute msg
place plane x y =
  placeWithOffset plane x y 0 0


{-| Place at coordinate, but you may add a SVG offset. See `place` above for important notes.
-}
placeWithOffset : Plane -> Float -> Float -> Float -> Float -> Attribute msg
placeWithOffset plane x y offsetX offsetY =
  transform ("translate(" ++ String.fromFloat (toSVGX plane x + offsetX) ++ "," ++ String.fromFloat (toSVGY plane y + offsetY) ++ ")")



-- INTERNAL HELPERS


range : Axis -> Float
range axis =
  let
    diff =
      axis.max - axis.min
  in
    if diff > 0 then diff else 1


innerLength : Axis -> Float
innerLength axis =
  Basics.max 1 (axis.length - axis.marginLower - axis.marginUpper)
