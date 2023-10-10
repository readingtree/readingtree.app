(**
   This file is apart of Reading Tree.

   AUTHOR:
   Rawley Fowler

   DESC:
   A module that handles all of the handlers for routes under /api
   all of these functions will return a JSON response. *)

(** Get all books by ids, we want this instead of a get all books
    because we'll probably have a crap ton of books. *)
let get_books_handler request =
  let (page, size) = Util.Dream.get_page_parameters request in
  let ids = List.map (fun s -> `String s) @@ Dream.queries request "ids" in
  if ids = [] then Dream.json "[]"
  else
    match%lwt Database.find_docs
                ~db:"books"
                ~mango:(`Assoc
                          [ ("keys", `List ids)
                          ; ("limit", `Int size)
                          ; ("skip", `Int (size * page))
                          ]
                       )
                ()
    with
    | Ok (Json_response books) ->
      books
      |> Json.to_string
      |> Dream.json
    | Ok (Text_response _ ) ->
      Dream.html ~status:`Internal_Server_Error
      @@ View.ServerError.render request
    | Error exn ->
      Dream.html ~status:`Internal_Server_Error
      @@ View.ServerError.render ~exn request

let get_tree_by_id_handler request =
  let id = Dream.param request "id" in
  match%lwt Database.find_doc ~db:"trees" ~id () with
  | Ok (Json_response json) ->
    begin
      match Json.member "docs" json with
      | Ok (`List []) -> Dream.empty `Not_Found
      | Ok (`List [tree]) -> Dream.json @@ Json.to_string tree
      | Ok _ ->
        Dream.html ~status:`Internal_Server_Error
        @@ View.ServerError.render ~exn:(Failure "Somehow got 2 documents with same id.") request
      | Error exn ->
        Dream.html ~status:`Internal_Server_Error
        @@ View.ServerError.render ~exn request
    end
  | Error _ | Ok (Text_response _) ->
    Dream.html ~status:`Internal_Server_Error
    @@ View.ServerError.render request

(** Get a list of trees, paginated by ?size and ?page. *)
let get_trees_paginated_handler request =
  let (page, size) = Util.Dream.get_page_parameters request in
  let skip = page * size in
  let mango =
    `Assoc (
      [ ("limit", `Int size)
      ; ("skip", `Int skip)
      ; ("fields", `List
           [ `String "_id"
           ; `String "title"
           ; `String "description"
           ; `String "tags"
           ; `String "children"
           ]
        )
      ]
    )
  in
  match%lwt Database.find_docs ~db:"trees" ~mango () with
  | Ok (Json_response json) -> Dream.json @@ Json.to_string json
  | Error exn ->
    Dream.html ~status:`Internal_Server_Error
    @@ View.ServerError.render ~exn request
  | _ -> Dream.empty `Bad_Request
