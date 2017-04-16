module Svg.Coordinates
  exposing
    ( Plane, Axis, Point, min, max
    , scaleSVG, toSVGX, toSVGY
    , scaleCartesian, toCartesianX, toCartesianY
    , place, placeWithOffset
    )

{-| First of all: If you're looking to a plotting library
 use [elm-plot](https://github.com/terezka/elm-plot) instead! If you feel
 like you're missing something in that library, you should just open an issue
 in that repo and I'll see what I can do to accommodate your needs.

That said, here are some cartesian to SVG coordinate translation helpers.

# Plane
@docs Plane, Axis

# Plane from data

You may want to produce a plane which fits all your data. For that you need
to find the minimum and maximum values withing your data in order to calculate
the domain and range.

@docs min, max

    planeFromPoints : List Coordinates.Point -> Coordinates.Plane
    planeFromPoints points =
      { x =
        { marginLower = 10
        , marginUpper = 10
        , length = 300
        , min = Coordinates.min .x points
        , max = Coordinates.max .x points
        }
      , y =
        { marginLower = 10
        , marginUpper = 10
        , length = 300
        , min = Coordinates.min .y points
        , max = Coordinates.max .y points
        }
      }

# Cartesian to SVG
@docs toSVGX, toSVGY, scaleSVG

# SVG to cartesian
@docs toCartesianX, toCartesianY, scaleCartesian

# Helpers
@docs Point, place, placeWithOffset

-}

import Svg exposing (Attribute)
import Svg.Attributes exposing (transform)



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
  - The length is the length of your SVG axis. (Plane.x.length is the width,
    Plane.y.length is the height)
  - The `min` and `max` values is the reach of your plane. (Domain for the y-axis, range
    for the x-axis)
-}
type alias Axis =
  { marginLower : Float
  , marginUpper : Float
  , length : Float
  , min : Float
  , max : Float
  }


{-| Helper to extract the minimum value amongst your coordinates.
-}
min : (a -> Float) -> List a -> Float
min toValue =
  List.map toValue
    >> List.minimum
    >> Maybe.withDefault 0


{-| Helper to extract the maximum value amongst your coordinates.
-}
max : (a -> Float) -> List a -> Float
max toValue =
  List.map toValue
    >> List.maximum
    >> Maybe.withDefault 1



-- TRANSLATION


{-| For scaling a cartesian value to a SVG value. Note that this will _not_
  return a coordinate on the plane, but the scaled value.
-}
scaleSVG : Axis -> Float -> Float
scaleSVG axis value =
  value * (innerLength axis) / (range axis)


{-| Translate a SVG x-coordinate to its cartesian x-coordinate.
-}
toSVGX : Plane -> Float -> Float
toSVGX plane value =
  scaleSVG plane.x (value - plane.x.min) + plane.x.marginLower


{-| Translate a SVG y-coordinate to its cartesian y-coordinate.
-}
toSVGY : Plane -> Float -> Float
toSVGY plane value =
  scaleSVG plane.y (plane.y.max - value) + plane.y.marginLower


{-| For scaling a SVG value to a cartesian value. Note that this will _not_
  return a coordinate on the plane, but the scaled value.
-}
scaleCartesian : Axis -> Float -> Float
scaleCartesian axis value =
  value * (range axis) / (innerLength axis)


{-| Translate a cartesian x-coordinate to its SVG x-coordinate.
-}
toCartesianX : Plane -> Float -> Float
toCartesianX plane value =
  scaleCartesian plane.x (value - plane.x.marginLower) + plane.x.min


{-| Translate a cartesian y-coordinate to its SVG y-coordinate.
-}
toCartesianY : Plane -> Float -> Float
toCartesianY plane value =
  range plane.y - scaleCartesian plane.y (value - plane.y.marginLower) + plane.y.min



-- PLACING HELPERS


{-| Representation of a point in your plane.
-}
type alias Point =
  { x : Float
  , y : Float
  }


{-| A `transform translate(x, y)` SVG attribute. Beware that using this and
  and another transform attribute on the same node, will overwrite the first.
  If that's the case, just make one yourself:

    myTransformAttribute : Svg.Attribute msg
    myTransformAttribute =
      transform <|
        "translate("
        ++ toString (toSVGX plane x) ++ ","
        ++ toString (toSVGY plane y) ++ ") "
        ++ "rotateX(" ++ whatever ++ ")"
-}
place : Plane -> Point -> Attribute msg
place plane point =
  placeWithOffset plane point 0 0


{-| Place at coordinate, but you may add a SVG offset. See `place` above for important notes.
-}
placeWithOffset : Plane -> Point -> Float -> Float -> Attribute msg
placeWithOffset plane { x, y } offsetX offsetY =
  transform ("translate(" ++ toString (toSVGX plane x + offsetX) ++ "," ++ toString (toSVGY plane y + offsetY) ++ ")")



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
