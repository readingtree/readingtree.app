module Global = struct
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
end

module Auth = struct
  let requires_role ~role next request =
    match Option.map (fun r -> r = role) (Dream.session_field request "role") with
    | Some true -> next request
    | Some false | None -> Dream.html ~status:`Unauthorized "403 Unauthorized"

  let redirect_unauthenticated ~location next request =
    match Dream.session_field request "user" with
    | Some _ -> next request
    | None -> Dream.redirect request location

  let redirect_authenticated ~location next request =
    match Dream.session_field request "user" with
    | None -> next request
    | Some _ -> Dream.redirect request location
end
