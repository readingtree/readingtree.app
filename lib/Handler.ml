open Lwt.Syntax

(** Utils that dont really fit in Util.ml *)
let _get_page_parameters request =
  let size =
    match Dream.query request "size" with
    | Some size ->
      begin
        match int_of_string_opt size with
        | Some i -> i
        | None -> 10
      end
    | None -> 10
  in
  let page =
    match Dream.query request "page" with
    | Some page ->
      begin
        match int_of_string_opt page with
        | Some i -> i
        | None -> 0
      end
    | None -> 0
  in
  (size, page)

(** Render the index page *)
let index_view_handler request = Dream.html @@ View.Index.render request

(** Render the tree list view page *)
let trees_list_view_handler request =
  let (page, size) = _get_page_parameters request in
  match%lwt Database.find_docs ~db:"trees" ~mango:(`Assoc [("limit", `Int size); ("skip", `Int (size * page))]) () with
  | Ok (Json_response (json)) ->
    let () = print_endline @@ Json.to_string (json) in
    begin
      match Json.member "rows" json with
      | Ok (`List trees) ->
        let trees = List.filter_map (fun tree -> match Type.Tree.of_yojson tree with Ok t -> Some t | Error e -> Dream.error (fun log -> log ~request "%s" e); None) trees in
        Dream.html @@ View.Trees.render ~trees request
      | Ok _ | Error _ -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render request
    end
  | Ok (Text_response _) -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render request
  | Error exn -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render ~exn request

(** Render the login page *)
let login_view_handler request = Dream.html @@ View.Login.render request

(** Handle a login form submission *)
let login_handler request =
  match%lwt Dream.form ~csrf:true request with
  | `Ok [ "name", name
        ; "password", password ] ->
    begin
      let password = Util.Hash.hash_string password in
      let mango =
        `Assoc
          [ ("fields", `List [`String "_id"; `String "name"; `String "role"] )
          ; ("selector",
             `Assoc
               [ ("name", `String name)
               ; ("password", `String password)])]
      in
      match%lwt Database.find_doc ~db:"users" ~mango () with
      | Ok (Json_response json) ->
        begin
          match Json.member "docs" json with
          | Ok (`List [
              `Assoc
                [ ("_id", `String id)
                ; ("name", `String _)
                ; ("role", `String role)
                ]
            ]) ->
            let* () = Dream.set_session_field request "user" id in
            let* () = Dream.set_session_field request "is_admin" @@ string_of_bool (role = "admin") in
            Dream.redirect request "/"
          | Ok (`List []) -> Dream.html ~status:`Not_Found @@ View.Login.render request (** TODO: Render errors here. *)
          | Ok _ | Error _ -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render request
        end
      | Ok _ | Error _ -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render request
    end
  | `Wrong_session _ | `Expired _ -> Dream.redirect request "/login"
  | _ -> Dream.html ~status:`Bad_Request @@ View.BadRequest.render request

module Api = struct
  (** Get all books by ids, we want this instead of a get all books because we'll probably have a crap ton of books. *)
  let get_books_handler request =
    let (page, size) = _get_page_parameters request in
    let ids = List.map (fun s -> `String s) @@ Dream.queries request "ids" in
    if ids = [] then Dream.json "[]"
    else
      match%lwt Database.find_docs
                  ~db:"books"
                  ~mango:(`Assoc [("keys", `List ids); ("limit", `Int size); ("skip", `Int (size * page))])
                  ()
      with
      | Ok (Json_response books) -> books |> Json.to_string |> Dream.json
      | Ok (Text_response _ ) -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render request
      | Error exn -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render ~exn request

  (** Get a list of trees, paginated by ?size and ?page. *)
  let get_trees_paginated_handler request =
    let (page, size) = _get_page_parameters request in
    let skip = page * size in
    let mango =
      `Assoc (
        [ ("limit", `Int size)
        ; ("skip", `Int skip)
        ]
      )
    in
    match%lwt Database.find_docs ~db:"trees" ~mango () with
    | Ok (Json_response json) -> Dream.json @@ Json.to_string json
    | Error exn ->
      Dream.html ~status:`Internal_Server_Error
      @@ View.ServerError.render ~exn request
    | _ -> Dream.empty `Bad_Request

end
