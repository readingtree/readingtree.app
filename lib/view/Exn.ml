let from_exn request =
  function
  | Not_found -> NotFound.render request |> Dream.html ~status:`Not_Found
  | exn -> ServerError.render ~exn request |> Dream.html ~status:`Internal_Server_Error
