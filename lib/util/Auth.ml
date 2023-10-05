let logged_in request =
  match Dream.session "user" request with
  | Some _ -> true
  | None -> false
