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
      | Ok (Json_response ((`Assoc doc) as json)) ->
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
        | Ok (Json_response (`Assoc doc as json)) ->
          begin
            match Json.member "children" json with
            | Ok (`List children) ->
              begin
                let to_save = (`Assoc (("children", `List (child :: children)) :: (List.filter (fun (k, _) -> k <> "children") doc))) in
                match%lwt Database.save_doc
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
  match%lwt Database.find_doc ~db:"readingtree" ~id () with
  | Ok (Json_response json) ->
    begin
      match Json.member "description" json with
      | Ok (`String description) ->
        Dream.html @@
        View.Tree.render
          ~scripts:["https://cdnjs.cloudflare.com/ajax/libs/vis/4.19.1/vis.min.js"]
          ~description
          request
      | Ok _ -> Dream.html ~status:`Not_Found @@ View.NotFound.render request
      | Error exn -> View.Exn.from_exn request exn
    end
  | Ok _ -> failwith "Unreachable"
  | Error exn -> View.Exn.from_exn request exn

(** Render the tree list view page *)
let trees_list_view_handler request =
  let (page, size) = Util.Dream.get_page_parameters request in
  match%lwt Database.find_all_docs
              ~db:"readingtree"
              ~paginate:(page, size)
              ()
  with
  | Ok (Json_response (json)) ->
    begin
      match Json.member "docs" json with
      | Ok (`List trees) ->
        let trees =
          List.filter_map
            (fun tree ->
               match (Json.member "_id" tree, Json.member "description" tree) with
               | (Ok (`String id), Ok (`String description)) -> Some (id, description)
               | _ -> Dream.error (fun log -> log ~request "Encountered error in tree_list_view_handler"); None)
            trees
        in
        Dream.html @@ View.Trees.render ~trees request
      | Ok _ -> failwith "Unreachable"
      | Error exn -> View.Exn.from_exn request exn
    end
  | Ok (Text_response _) -> failwith "Unreachable"
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
      | Ok (Json_response json) ->
        let () = Dream.log "%s" @@ Json.pp json in
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
            Dream.redirect request referrer
          | Ok (`List []) ->
            Dream.html ~status:`Not_Found
            @@ View.Login.render request ~errors:[("login", "We couldn't find a user that matches those credentials.")]
          | Ok _ -> failwith "Unreachable"
          | Error exn -> View.Exn.from_exn request exn
        end
      | Ok _ -> failwith "Unreachable"
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
