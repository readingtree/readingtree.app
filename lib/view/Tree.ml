(** TODO: Use the .description from the tree in question as the title and add to the TXT below. *)
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
          [ txt "" ] (** TODO: Add description here as an H1 probably. *)
      ; div ~a:[ a_class [ "vw-100"; "vh-100" ]; a_id "tree" ] []
      ]
      request
  in
  Render.to_string html
