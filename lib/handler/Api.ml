(**
   This file is apart of Reading Tree.

   AUTHOR:
   Rawley Fowler

   DESC:
   A module that handles all of the handlers for routes under /api
   all of these functions will return a JSON response. *)

(** Get a tree by its id. *)
let get_tree_by_id_handler request =
  let id = Dream.param request "id" in
  match%lwt Database.find_doc ~db:"readingtree" ~id () with
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
  | Ok (Text_response _) -> failwith "Unreachable"
  | Error exn ->
    let () = print_endline @@ Printexc.to_string exn in
    Dream.html ~status:`Internal_Server_Error
    @@ View.ServerError.render ~exn request

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
  match%lwt Database.find_docs ~db:"readingtree" ~mango () with
  | Ok (Json_response json) -> Dream.json @@ Json.to_string json
  | Error exn ->
    Dream.html ~status:`Internal_Server_Error
    @@ View.ServerError.render ~exn request
  | _ -> Dream.empty `Bad_Request
