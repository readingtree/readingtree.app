let render request =
  let open Tyxml.Html in
  let html =
    Layout.Vue.layout
      ~init:"tree.js"
      ~title:"Reading Tree"
      [ div
          ~a:[ Unsafe.string_attrib "v-if" "error" ]
          [ txt "{{error}}" ]
      ; div ~a:[ Unsafe.string_attrib "v-if" "tree" ]
          [ txt "{{tree}}" ]
      ]
      request
  in
  Render.to_string html
