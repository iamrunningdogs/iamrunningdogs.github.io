module Route.Tags exposing (ActionData, Data, Model, Msg, route)

import BackendTask exposing (BackendTask)
import DateTime
import Effect
import Element as UI
import FatalError exposing (FatalError)
import Head
import PagesMsg exposing (PagesMsg)
import Posts
import Route
import RouteBuilder exposing (App, StatefulRoute)
import SeoConfig exposing (defaultSeo)
import Shared
import UrlPath
import Utils exposing (..)
import View exposing (View)
import Widgets


type alias Model =
    { search_text : String
    }


type Msg
    = Msg_SearchTextChanged String


type alias RouteParams =
    {}


type alias Data =
    { posts : List Posts.PostHeader
    }


type alias ActionData =
    {}


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { head = head
        , data = data
        }
        |> RouteBuilder.buildWithLocalState
            { init = init
            , subscriptions = subscriptions
            , update = update
            , view = view
            }


data : BackendTask FatalError Data
data =
    Posts.allBlogPosts
        |> BackendTask.andThen (List.map Posts.loadPostHeader >> BackendTask.combine)
        |> BackendTask.map (List.sortWith <| \a b -> DateTime.compareNewer a.date b.date)
        |> BackendTask.map Data


title : String
title =
    "Índice de etiquetas — Asier Elorz"


head :
    App Data ActionData RouteParams
    -> List Head.Tag
head _ =
    SeoConfig.makeHeadTags { defaultSeo | title = title }


init : App Data ActionData RouteParams -> Shared.Model -> ( Model, Effect.Effect Msg )
init _ _ =
    ( { search_text = "" }, Effect.none )


subscriptions : RouteParams -> UrlPath.UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions _ _ _ _ =
    Sub.none


update : App Data ActionData RouteParams -> Shared.Model -> Msg -> Model -> ( Model, Effect.Effect Msg )
update _ _ msg model =
    case msg of
        Msg_SearchTextChanged new_search_text ->
            ( { model | search_text = new_search_text }, Effect.none )


view :
    App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg Msg)
view app _ model =
    { title = title
    , body =
        let
            -- Posts grouped by month they were published
            grouped_posts =
                app.data.posts
                    |> List.filter (Posts.passesFilter model.search_text)
                    |> Posts.groupBy (\post -> post.tags)
                    |> List.sortBy Tuple.first


            view_grouped_posts : ( String, List Posts.PostHeader ) -> UI.Element msg
            view_grouped_posts ( tag, posts_for_a_month ) =
                UI.column [ UI.spacing 10, UI.width UI.fill ]
                    (Widgets.heading [ UI.paddingEach { bottom = 10, top = 0, left = 0, right = 0 } ] 3 (kebab_case_to_sentence <| capitalize tag) :: List.map Widgets.postMenuEntry posts_for_a_month)

            search_box =
                Widgets.searchBox (PagesMsg.fromMsg << Msg_SearchTextChanged) model.search_text
        in
        UI.column
            [ UI.spacing 40 ]
            (search_box :: List.map view_grouped_posts grouped_posts)
    }
