open Readingtree (* Import all of the functions in the Application module *)

(** Web endpoint declaration *)
let main () =
  let open Dream in (* Locally import all of the Dream web framework functions *)
  run
  @@ logger
  @@ set_secret (to_base64url (random 32))
  @@ cookie_sessions
  @@ router
       [ get "/" Handler.index_handler ]

let () = main ()
