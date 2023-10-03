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
  @@ D.router
       [ D.get "/" Handler.index_view_handler
       ; D.get "/trees" Handler.trees_list_view_handler
       ; D.scope "/api" []
           [ D.get "/trees" @@ Handler.get_trees_paginated_handler
           ; D.get "/books" @@ Handler.get_books_handler
           ]
       ]
