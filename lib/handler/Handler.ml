(**
   This file is apart of Reading Tree.

   AUTHOR:
   Rawley Fowler <rawleyfowler@proton.me>

   DESC:
   A module that handles all of the handlers for non API routes. 
   All of these should return non-json responses.
   See the [Api] module for API related handlers. *)

open Lwt.Syntax

module Api = Api

let add_edge_to_tree_handler request =
  let tree_id = Dream.param request "id" in
  match%lwt Dream.form ~csrf:true request with
  | `Ok [ ("from", from)
        ; ("to", _to) ] ->
    begin
      let new_edge = `Assoc [("to", `String _to); ("from", `String from)] in
      match%lwt Database.find_doc ~db:"readingtree" ~id:tree_id () with
      | Ok ((`Assoc doc) as json) ->
        begin
          match Json.member "edges" json with
          | Ok (`List edges) ->
            let to_save = (`Assoc (("edges", `List (new_edge :: edges)) :: (List.filter (fun (k, _) -> k <> "edges") doc))) in
            begin
              match%lwt Database.save_doc
                          ~db:"readingtree"
                          ~id:tree_id
                          ~doc:to_save
                          ()
              with
              | Ok _ -> Dream.redirect request ("/trees/" ^ tree_id)
              | Error exn -> View.Exn.from_exn request exn
            end
          | Ok _ -> failwith "Unreachable"
          | Error exn -> View.Exn.from_exn request exn
        end
      | Ok _ -> failwith "Unreachable"
      | Error exn -> View.Exn.from_exn request exn
    end
  | _ -> Dream.html ~status:`Bad_Request @@ View.BadRequest.render request

let add_book_to_tree_handler request =
  let tree_id = Dream.param request "id" in
  match%lwt Dream.form ~csrf:true request with
  | `Ok [ "author", author
        ; "cover", cover
        ; "id", _id
        ; "isbn", isbn
        ; "title", title
        ]
    ->
    let child_book = `Assoc
        [ ("title", `String title)
        ; ("cover", `String cover)
        ; ("isbn", `String isbn)
        ; ("author", `String author)
        ]
    in
    let child = `Assoc
        [ ("_id", `String _id)
        ; ("description", `String title)
        ; ("typ", `String "tree")
        ; ("book", child_book)
        ]
    in
    begin
      match%lwt Database.find_doc ~db:"readingtree" ~id:tree_id () with
      | Ok (`Assoc doc as json) ->
        begin
          match Json.member "children" json with
          | Ok (`List children) ->
            begin
              let to_save =
                (`Assoc
                   (("children", `List (child :: children)) ::
                    (List.filter (fun (k, _) -> k <> "children") doc)))
              in
              match%lwt
                Database.save_doc
                  ~db:"readingtree"
                  ~id:tree_id
                  ~doc:to_save
                  ()
              with
              | Ok (_) -> Dream.redirect request ("/trees/" ^ tree_id)
              | Error exn -> View.Exn.from_exn request exn
            end
          | _ -> Dream.empty `Internal_Server_Error
        end
      | Ok _ -> View.Exn.from_exn request (Failure "Unknown error.")
      | Error exn -> View.Exn.from_exn request exn
    end
  | _ ->
    Dream.html ~status:`Bad_Request
    @@ View.BadRequest.render request

(** Render the index page *)
let index_view_handler request = Dream.html @@ View.Index.render request

(** Render a tree page. JavaScript will pull the tree from the API. *)
let tree_view_handler request =
  let id = Dream.param request "id" in
  let* tree = Database.find_doc ~db:"readingtree" ~id () in
  let* read_books =
    let return = Lwt.return in
    match Dream.session_field request "user" with
    | Some id ->
      begin
        match%lwt Database.find_doc ~db:"users" ~id () with
        | Ok json ->
          begin
            match Json.member "books" json with
            | Ok (`List books) -> return books
            | _ -> return []
          end
        | _ -> return []
      end
    | None -> return []
  in
  match tree with
  | Ok json ->
    begin
      match Json.member "description" json with
      | Ok (`String description) ->
        Dream.html @@
        View.Tree.render
          ~read_books
          ~scripts:[ "https://cdnjs.cloudflare.com/ajax/libs/vis-network/9.1.8/standalone/umd/vis-network.min.js" ]
          ~description
          request
      | Ok _ -> Dream.html ~status:`Not_Found @@ View.NotFound.render request
      | Error exn -> View.Exn.from_exn request exn
    end
  | Error exn -> View.Exn.from_exn request exn

(** Mark as read handler. TODO: Make a little nicer later. *)
let mark_as_read_handler request =
  let book_id = Dream.param request "book_id" in
  let tree_id = Dream.param request "tree_id" in
  let redirect_target = ("/trees/" ^ tree_id) in
  match%lwt Database.find_doc ~db:"readingtree" ~id:tree_id () with
  | Ok tree ->
    let has_book =
      match ( Json.member "children" tree
            , Json.member "_id" tree )
      with
      | Ok (`List books), Ok(`String _ as _id) ->
        let books = _id :: (List.map (fun book -> Yojson.Safe.Util.member "_id" book) books) in
        let () = List.iter (function `String s -> print_endline s | t -> print_endline @@ Json.pp t) books in
        Option.is_some @@ List.find_opt (function `String s -> s = book_id | _ -> false) books
      | _ -> false
    in
    if not has_book then Dream.html ~status:`Not_Found @@ View.NotFound.render request
    else
      begin
        match Dream.session_field request "user" with
        | Some user_id ->
          begin
            let* user = Database.find_doc ~db:"users" ~id:user_id () in
            match user with
            | Ok user ->
              begin
                let is_allowed_to_read time =
                  let now = Ptime_clock.now () in
                  let span = time |> Ptime.diff now |> Ptime.Span.to_float_s in
                  span > 86400.00
                in
                let read_book book_id user_id =
                  match%lwt Database.find_doc ~db:"users" ~id:user_id () with
                  | Ok (`Assoc json as user) ->
                    begin
                      match Json.member "books" user with
                      | Ok (`List books) ->
                        let new_books = `List ((`String book_id) :: books) in
                        let new_read_time = `String (Ptime_clock.now () |> Ptime.to_float_s |> Float.to_string) in
                        let to_save = (`Assoc (("books", new_books) ::
                                               ("lastReadTime", new_read_time) ::
                                               (List.filter (fun (k, _) -> not (k = "books" || k = "lastReadTime")) json)))
                        in
                        print_endline @@ Json.pp to_save;
                        begin
                          match%lwt
                            Database.save_doc
                              ~db:"users"
                              ~id:user_id
                              ~doc:to_save
                              ()
                          with
                          | Ok _ -> Dream.redirect request redirect_target
                          | Error exn -> View.Exn.from_exn request exn
                        end
                      | Ok _ -> Dream.html ~status:`Bad_Request @@ View.BadRequest.render request
                      | Error exn -> View.Exn.from_exn request exn
                    end
                  | Ok _ -> View.Exn.from_exn request (Failure "Internal Server Error")
                  | Error exn -> View.Exn.from_exn request exn
                in
                let can_read =
                  begin
                    match Json.member "lastReadTime" user with
                    | Ok `Null -> Ok true
                    | Ok `String float_time ->
                      begin
                        match Ptime.of_float_s (Float.of_string float_time) with
                        | Some time -> Ok (is_allowed_to_read time)
                        | None -> Ok false
                      end
                    | Ok _ | Error _ -> Error false
                  end
                in
                match can_read with
                | Ok true -> read_book book_id user_id
                | Ok false ->
                  let () = Dream.add_flash_message request "danger" "You've already read a book in the last 24 hours." in
                  Dream.redirect request redirect_target
                | Error _ -> View.Exn.from_exn request (Failure "Something went really wrong.")
              end
            | Error exn -> View.Exn.from_exn request exn
          end
        | None -> Dream.redirect request "/login"
      end
  | Error exn -> View.Exn.from_exn request exn

(** Render the tree list view page *)
let trees_list_view_handler request =
  let (page, size) = Util.Dream.get_page_parameters request in
  match%lwt Database.find_all_docs
              ~db:"readingtree"
              ~paginate:(page, size)
              ()
  with
  | Ok json ->
    begin
      match Json.member "docs" json with
      | Ok (`List trees) ->
        let trees =
          List.filter_map
            (fun tree ->
               match ( Json.member "_id" tree
                     , Json.member "description" tree
                     , Json.member "children" tree)
               with
               | ( Ok (`String id)
                 , Ok (`String description)
                 , Ok (`List children) ) -> Some (id, description, (List.length children))
               | _ -> Dream.error (fun log -> log ~request "Encountered error in tree_list_view_handler"); None)
            trees
        in
        Dream.html @@ View.Trees.render ~trees request
      | Ok _ -> failwith "Unreachable"
      | Error exn -> View.Exn.from_exn request exn
    end
  | Error exn -> View.Exn.from_exn request exn

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
      match Validation.validate_sign_up ~name ~email ~password ~confirm () with
      | [] ->
        begin
          let* name_exists_result = Validation.validate_field_unique ~db:"users" "name" (`String name) in
          let* email_exists_result = Validation.validate_field_unique ~db:"users" "email" (`String email) in
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
              | Ok () ->
                let () = Dream.add_flash_message request "success" "You signed up successfully. Please log in." in
                Dream.redirect request "/login"
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
        ; "password", password
        ; "referrer", referrer ] ->
    begin
      let password = Util.Hash.hash_string password in
      let mango =
        `Assoc
          [ ("fields", `List [`String "_id"; `String "name"; `String "role"] )
          ; ("selector",
             `Assoc
               [ ("name", `String name)
               ; ("password", `String password)])
          ]
      in
      match%lwt Database.find_docs ~db:"users" ~mango () with
      | Ok json ->
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
            let* () = Dream.set_session_field request "role" role in
            let () = Dream.add_flash_message request "success" "You logged in successfully." in
            Dream.redirect request referrer
          | Ok (`List []) ->
            Dream.html ~status:`Not_Found
            @@ View.Login.render request ~username:name ~errors:[("login", "We couldn't find a user that matches those credentials.")]
          | Ok _ -> failwith "Unreachable"
          | Error exn -> View.Exn.from_exn request exn
        end
      | Error exn -> View.Exn.from_exn request exn
    end
  | `Wrong_session _ | `Expired _ -> Dream.redirect request "/login"
  | _ ->
    Dream.html ~status:`Bad_Request
    @@ View.BadRequest.render request

(** Logs the user out on any method to "/logout" *)
let logout_handler request =
  let* () = Dream.invalidate_session request in
  Dream.redirect request "/login"

(** Profile handler *)
let profile_view_handler request =
  let id = Dream.param request "id" in
  match%lwt Database.find_doc ~db:"users" ~id () with
  | Ok user
    ->
    let open Yojson.Safe.Util in
    Dream.html @@
    View.Profile.render
      ~user_id:id
      ~num_books:(user |> member "books" |> to_list |> List.length)
      ~last_read_time:(user |> member "lastReadTime" |> to_string)
      ~name:(user |> member "name" |> to_string)
      request
  | Error exn -> View.Exn.from_exn request exn

let change_password_handler request =
  let user_id = Dream.param request "id" in
  let logged_in_user_id = Option.get @@ Dream.session_field request "user" in
  let redirect_target = ("/profile/" ^ user_id) in
  if user_id = logged_in_user_id then
    begin
      match%lwt Dream.form ~csrf:true request with
      | `Ok
          [ "confirm-password", confirm
          ; "password", password
          ]
        ->
        let is_password_valid = Validation.validate_password ~password () in
        if is_password_valid && (password = confirm) then
          begin
            match%lwt Database.find_doc ~db:"users" ~id:user_id () with
            | Ok (`Assoc user) ->
              let hash = Util.Hash.hash_string password in
              let to_save = `Assoc (
                  ("password", `String hash) :: (List.filter (fun (k, _) -> k <> "password") user)
                )
              in
              begin
                match%lwt Database.save_doc ~db:"users" ~id:user_id ~doc:to_save () with
                | Ok _ -> Dream.redirect request redirect_target
                | Error exn -> View.Exn.from_exn request exn
              end
            | Ok _ -> failwith "Unreachable"
            | Error exn -> View.Exn.from_exn request exn
          end
        else
          let () = Dream.add_flash_message request "danger" "Your password is invalid." in
          Dream.redirect request redirect_target
      | `Wrong_session _ | `Expired _ -> Dream.redirect request "/login"
      | _ ->
        Dream.html ~status:`Bad_Request
        @@ View.BadRequest.render request
    end
  else
    Dream.html @@ View.BadRequest.render request

let privacy_policy_view_handler request = Dream.html @@ View.PrivacyPolicy.render request

let terms_of_service_view_handler request = Dream.html @@ View.TermsOfService.render request
