let render request =
  let open Tyxml.Html in
  let tree_id = Dream.param request "id" in
  let html =
    Layout.Vue.layout
      ~title:"Reading Tree"
      [ txt "{{message}}"
      ; script (txt (Printf.sprintf "const treeId = '%s';" tree_id))
      ]
      request
  in
  Render.to_string html
