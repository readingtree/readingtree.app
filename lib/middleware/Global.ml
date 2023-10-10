let assign_guest next request =
  let open Lwt.Syntax in
  match Dream.session_field request "user" with
  | Some _ -> next request
  | None ->
    let* () = Dream.set_session_field request "role" "guest" in
    next request

let exception_handler next req =
  Lwt.catch
    (fun () -> next req)
    (fun exn ->
       Dream.log "Exception Caught: %s" (Printexc.to_string exn);
       Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render ~exn req)
