open Readingtree

(* Database creates are idempotent in CouchDB *)
let migrations =
  [ (fun () -> Database.create_db ~name:"trees")
  ; (fun () -> Database.create_db ~name:"users")
  ]

(** Web endpoint declaration *)
let () =
  let () = List.iter (fun m -> m () |> Lwt.map (fun _ -> ()) |> Lwt_main.run ) migrations in
  let module D = Dream in
  D.run
  @@ D.logger
  @@ D.set_secret (D.to_base64url (D.random 32))
  @@ D.cookie_sessions
  @@ D.router
       [ D.get "/" Handler.index_handler ]
