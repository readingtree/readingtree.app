let requires_role ~role next request =
  match Option.map (fun r -> r = role) (Dream.session_field request "role") with
  | Some true -> next request
  | Some false | None -> Dream.html ~status:`Unauthorized "403 Unauthorized"

let redirect_unauthenticated ?(referrer=false) ~location next request =
  match Dream.session_field request "user" with
  | Some _ -> next request
  | None ->
    if referrer then
      let referrer = Dream.target request in
      Dream.redirect request (location ^ ("?referrer=" ^ referrer))
    else
      Dream.redirect request location

let redirect_authenticated ~location next request =
  match Dream.session_field request "user" with
  | None -> next request
  | Some _ -> Dream.redirect request location
