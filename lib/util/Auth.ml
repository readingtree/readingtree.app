let logged_in request =
  match Dream.session "user" request with
  | Some _ -> true
  | None -> false

let is_admin request =
  match Dream.session "role" request with
  | None -> false
  | Some "admin" -> true
  | Some _ -> false
