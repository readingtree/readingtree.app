let render request =
  let open Tyxml.Html in
  Unsafe.data @@ Dream.csrf_tag request
