let render
    ?(scripts=[])
    ?(styles=[])
    ~description
    request =
  let open Tyxml.Html in
  let html =
    Layout.Vue.layout
      ~init:"tree.js"
      ~title:"Reading Tree"
      ~scripts
      ~styles
      [ h1 [ txt description ]
      ; div ~a:[ a_class [ "vw-100"; "vh-100" ]; a_id "tree" ] []
      ]
      request
  in
  Render.to_string html
