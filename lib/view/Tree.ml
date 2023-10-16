let render
    ?(scripts=[])
    ?(styles=[])
    ~description
    request =
  let open Tyxml.Html in
  let id = Dream.param request "id" in
  let html =
    Layout.Vue.layout
      ~init:"tree.js"
      ~title:"Reading Tree"
      ~scripts
      ~styles
      [ h1 [ txt description ]
      ; (if Util.Auth.is_admin request then Partial.Tree_admin_form.render ~id request else (div []))
      ; div ~a:[ a_class [ "vw-100"; "vh-100" ]; a_id "tree" ] []
      ]
      request
  in
  Render.to_string html
