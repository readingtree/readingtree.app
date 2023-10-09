open Lwt.Syntax

(** Render the index page *)
let index_view_handler request = Dream.html @@ View.Index.render request

(** Render the tree list view page *)
let trees_list_view_handler request =
  let (page, size) = Util.Dream.get_page_parameters request in
  match%lwt Database.find_docs ~db:"trees" ~mango:(`Assoc [("limit", `Int size); ("skip", `Int (size * page))]) () with
  | Ok (Json_response (json)) ->
    let () = print_endline @@ Json.to_string (json) in
    begin
      match Json.member "rows" json with
      | Ok (`List trees) ->
        let trees = List.filter_map (fun tree -> match Type.Tree.of_yojson tree with Ok t -> Some t | Error e -> Dream.error (fun log -> log ~request "%s" e); None) trees in
        Dream.html @@ View.Trees.render ~trees request
      | Ok _ | Error _ ->
        Dream.html ~status:`Internal_Server_Error
        @@ View.ServerError.render request
    end
  | Ok (Text_response _) ->
    Dream.html ~status:`Internal_Server_Error
    @@ View.ServerError.render request
  | Error exn ->
    Dream.html ~status:`Internal_Server_Error
    @@ View.ServerError.render ~exn request

(** Render the signup page *)
let signup_view_handler request = Dream.html @@ View.Signup.render request

(** Handle a signup for submission *)
let signup_handler request =
  match%lwt Dream.form ~csrf:true request with
  | `Ok [ "email", email
	      ; "name", name
	      ; "password", password
	      ; "password_confirm", confirm
	      ] ->
    begin
      match Validate.validate_sign_up ~name ~email ~password ~confirm () with
      | [] ->
        begin
          let* name_exists_result = Validate.validate_field_unique ~db:"users" "name" (`String name) in
          let* email_exists_result = Validate.validate_field_unique ~db:"users" "email" (`String email) in
          match (name_exists_result, email_exists_result) with
          | (Ok true, Ok true) ->
            begin
              let user = `Assoc (
                  [ ("name", `String name)
                  ; ("email", `String email)
                  ; ("password", `String (Util.Hash.hash_string password))
                  ; ("role", `String "user")
                  ; ("books", `List [])
                  ]
                )
              in
              match%lwt Database.create_doc ~db:"users" ~doc:user () with
              | Ok () -> Dream.redirect request "/login"
              | Error _ ->
                Dream.html ~status:`Internal_Server_Error
                @@ View.Signup.render ~name ~email ~errors:[("server", "Something went wrong creating your account try again later")] request
            end
          | (Ok name_exists, Ok email_exists) ->
            let errors =
              List.filter_map
                (fun (b, key, error) -> if not b then Some (key, error) else None)
                [(name_exists, "name", "That name is already in use."); (email_exists, "email", "That email is already in use.")]
            in
            Dream.html ~status:`Bad_Request
            @@ View.Signup.render ~name ~email ~errors request
          | (Error _, Ok _) | (Ok _, Error _) | (Error _, Error _) ->
            Dream.html ~status:`Internal_Server_Error
            @@ View.Signup.render ~name ~email ~errors:[("server", "Something went wrong processing your signup. Please try again later.")] request
        end
      | errors ->
        Dream.html ~status:`Bad_Request
        @@ View.Signup.render ~name ~email ~errors request
    end
  | _ ->
    Dream.html ~status:`Bad_Request
    @@ View.BadRequest.render request

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
                ; ("name", `String name)
                ; ("role", `String role)
                ]
            ]) ->
            let* () = Dream.set_session_field request "user" id in
            let* () = Dream.set_session_field request "user_name" name in
            let* () = Dream.set_session_field request "is_admin" @@ string_of_bool (role = "admin") in
            Dream.redirect request "/"
          | Ok (`List []) ->
            Dream.html ~status:`Not_Found
            @@ View.Login.render request (** TODO: Render errors here. *)
          | Ok _ | Error _ ->
            Dream.html ~status:`Internal_Server_Error
            @@ View.ServerError.render request
        end
      | Ok _ | Error _ ->
        Dream.html ~status:`Internal_Server_Error
        @@ View.ServerError.render request
    end
  | `Wrong_session _ | `Expired _ -> Dream.redirect request "/login"
  | _ ->
    Dream.html ~status:`Bad_Request
    @@ View.BadRequest.render request

(** Logs the user out on any method to "/logout" *)
let logout_handler request =
  let* () = Dream.invalidate_session request in
  Dream.redirect request "/login"

(** A module that handles all of the handlers for routes under /api
    all of these functions will return a JSON response.
*)
module Api = struct
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
end
