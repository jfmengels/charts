module Route exposing (Route(..), top, documentation, section, example, gallery, quickStart, fromUrl, replaceUrl, toString)

import Browser.Navigation as Navigation
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, oneOf, s, string, int)
import Url.Parser.Query as Query
import Url.Builder as Builder


top : String
top =
  toString <| Top 


documentation : String
documentation =
  toString <| Documentation 


section : { section : String } -> String
section params =
  toString <| Documentation_String_ params.section


example : { section : String, example : String } -> String
example params =
  toString <| Documentation_String__String_ params.section params.example


gallery : String
gallery =
  toString <| Gallery 


quickStart : String
quickStart =
  toString <| Quick_start 


type Route
    = Top 
    | Documentation 
    | Documentation_String_ String
    | Documentation_String__String_ String String
    | Gallery 
    | Quick_start 


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


replaceUrl : Navigation.Key -> Route -> Cmd msg
replaceUrl key route =
    Navigation.replaceUrl key (toString route)


toString : Route -> String
toString route =
    case route of
        Top  ->
            Builder.absolute [] (List.filterMap identity [])

        Documentation  ->
            Builder.absolute ["documentation"] (List.filterMap identity [])

        Documentation_String_ p1 ->
            Builder.absolute ["documentation", p1] (List.filterMap identity [])

        Documentation_String__String_ p1 p2 ->
            Builder.absolute ["documentation", p1, p2] (List.filterMap identity [])

        Gallery  ->
            Builder.absolute ["gallery"] (List.filterMap identity [])

        Quick_start  ->
            Builder.absolute ["quick-start"] (List.filterMap identity [])


-- INTERNAL


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Top Parser.top
        , Parser.map Documentation (s "documentation")
        , Parser.map Documentation_String_ (s "documentation" </> string)
        , Parser.map Documentation_String__String_ (s "documentation" </> string </> string)
        , Parser.map Gallery (s "gallery")
        , Parser.map Quick_start (s "quick-start")
        ]