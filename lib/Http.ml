let request ?meth ?headers ?body uri =
  Hyper.request ?method_:meth ?headers ?body uri

let run ?redirect_limit ?server request =
  let open Lwt.Infix in
  try
    Hyper.run ?redirect_limit ?server request >>= fun res -> Lwt.return (Ok res)
  with
    exn -> Lwt.return (Error exn)
