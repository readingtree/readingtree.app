let render request =
  let open Tyxml.Html in
  let html =
    Layout.Default.layout
      ~title:"404 Not Found"
      [ h1 [ txt "404 Not Found" ]
      ; p
          [ txt "We couldn't find what you were looking for :("]
      ]
      request
  in
  Render.to_string html
