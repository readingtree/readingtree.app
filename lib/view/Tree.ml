let render
    ?(scripts=[])
    ?(styles=[])
    request =
  let open Tyxml.Html in
  let html =
    Layout.Vue.layout
      ~init:"tree.js"
      ~title:"Reading Tree"
      ~scripts
      ~styles
      [ div
          ~a:[ Unsafe.string_attrib "v-if" "error" ]
          [ txt "{{error}}" ]
      ; div ~a:[ a_id "tree" ] []
      ]
      request
  in
  Render.to_string html
