open Readingtree

(** Database creates are idempotent in CouchDB *)
let migrations =
  [ (Database.create_db ~name:"readingtree")
  ; (Database.create_db ~name:"users")
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
    ~interface:"0.0.0.0"
    ~port:8080
  @@ D.logger
  @@ D.set_secret (D.to_base64url (D.random 32))
  @@ D.cookie_sessions
  @@ D.flash
  @@ Middleware.Global.exception_handler
  @@ D.router
    [ D.get "/static/**" @@ D.static "static"
    ; D.get "/" Handler.trees_list_view_handler
    ; D.scope "/trees" []
        [ D.get "/:id" Handler.tree_view_handler
        ; D.post "/:id/books" @@ Middleware.Auth.requires_role ~role:"admin" Handler.add_book_to_tree_handler
        ; D.post "/:id/edges" @@ Middleware.Auth.requires_role ~role:"admin" Handler.add_edge_to_tree_handler
        ; D.get "" Handler.trees_list_view_handler
        ; D.get "/" Handler.trees_list_view_handler
        ; D.post "/:tree_id/mark-read/:book_id" @@ Middleware.Auth.redirect_unauthenticated ~location:"/login" Handler.mark_as_read_handler
        ]
    ; D.any "/logout" (fun request -> Middleware.Auth.redirect_unauthenticated ~location:"/" Handler.logout_handler request )
    ; D.scope "/" [ Middleware.Auth.redirect_authenticated ~location:"/" ]
        [ D.get "/login" Handler.login_view_handler
        ; D.post "/login" Handler.login_handler
        ; D.get "/signup" Handler.signup_view_handler
        ; D.post "/signup" Handler.signup_handler
        ]
    ; D.scope "/api" []
        [ D.get "/trees" @@ Handler.Api.get_trees_paginated_handler
        ; D.get "/trees/:id" @@ Handler.Api.get_tree_by_id_handler
        ]
    ; D.any "/privacy" @@ Handler.privacy_policy_handler
    ; D.any "/tos" @@ Handler.terms_of_service_handler
    ]
