let render request =
  let open Tyxml.Html in
  let html =
    Layout.Default.layout
      ~title:"Reading Tree"
      [ p [ txt "Welcome to Reading Tree!" ] ]
      request
  in
  Render.to_string html
