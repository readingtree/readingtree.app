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

(** Render the index page *)
let index_view_handler request = Dream.html @@ View.Index.render request

(** Render a tree page. JavaScript will pull the tree from the API. *)
let tree_view_handler request =
  Dream.html @@
  View.Tree.render
    ~scripts:["https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"]
    request

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
               match Type.Tree.of_yojson tree with
               | Ok t -> Some t
               | Error e -> Dream.error (fun log -> log ~request "Encountered error in tree_list_view_handler: %s" e); None)
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
