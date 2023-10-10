open Readingtree

(** Database creates are idempotent in CouchDB *)
let migrations =
  [ (Database.create_db ~name:"trees")
  ; (Database.create_db ~name:"users")
  ; (Database.create_db ~name:"books")
  ]

(** Web endpoint declaration *)
let () =
  (* Run the migrations *)
  let () = List.iter (fun m ->
      m ()
      |> Lwt.map (fun _ -> ())
      |> Lwt_main.run
    ) migrations
  in
  let module D = Dream in
  D.run
  @@ D.logger
  @@ D.set_secret (D.to_base64url (D.random 32))
  @@ D.cookie_sessions
  @@ Middleware.Global.exception_handler
  @@ D.router
       [ D.get "/" Handler.index_view_handler
       ; D.get "/trees" Handler.trees_list_view_handler
       ; D.get "/login" Handler.login_view_handler
       ; D.post "/login" Handler.login_handler
       ; D.any "/logout" (fun request -> Middleware.Auth.redirect_unauthenticated ~location:"/" Handler.logout_handler request )
       ; D.get "/signup" Handler.signup_view_handler
       ; D.post "/signup" Handler.signup_handler
       ; D.scope "/api" [ Middleware.Auth.requires_role ~role:"user" ]
           [ D.get "/trees" @@ Handler.Api.get_trees_paginated_handler
           ; D.get "/trees/:id" @@ Handler.Api.get_tree_by_id_handler
           ; D.get "/books" @@ Handler.Api.get_books_handler
           ]
       ]
