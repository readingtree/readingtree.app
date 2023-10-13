let render request =
  let open Tyxml.Html in
  let html =
    Layout.Vue.layout
      ~init:"tree.js"
      ~title:"Reading Tree"
      [ txt "{{message}}" ]
      request
  in
  Render.to_string html
