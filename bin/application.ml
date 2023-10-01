open Readingtree

(** Web endpoint declaration *)
let () =
  let module D = Dream in
  D.run
  @@ D.logger
  @@ D.set_secret (D.to_base64url (D.random 32))
  @@ D.cookie_sessions
  @@ D.router
       [ D.get "/" Handler.index_handler ]
