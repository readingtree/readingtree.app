let render
    ?(read_books=[])
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
      ~read_books
      ~scripts
      ~styles
      [ h1 [ txt description ]
      ; (if Util.Auth.is_admin request then Partial.Tree_admin_form.render ~id request else (div []))
      ; div ~a:[ a_class [ "vw-100"; "vh-100" ]; a_id "tree" ] []
      ; Partial.Modal.render
          ~id:"book-modal"
          ~title:""
          ~content:[]
          ~footer:
            [ button
                ~a:[ a_class [ "btn"; "btn-success"]
                   ; a_button_type `Button
                   ]
                [ txt "Mark as Read" ]
            ]
      ]
      request
  in
  Render.to_string html
