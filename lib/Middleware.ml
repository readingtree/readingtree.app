module Global = struct
  let assign_guest next request =
    let open Lwt.Syntax in
    match Dream.session_field request "user" with
    | Some _ -> next request
    | None ->
      let* () = Dream.set_session_field request "role" "guest" in
      next request
end

module Auth = struct
  let requires_role ~role next request =
    match Option.map (fun r -> r = role) (Dream.session_field request "role") with
    | Some true -> next request
    | Some false | None -> Dream.html ~status:`Unauthorized "403 Unauthorized"
end
