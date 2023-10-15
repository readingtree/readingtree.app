let render ~trees request =
  let open Tyxml.Html in
  let tree_views = List.map (fun (id, description) -> Partial.Tree_card.render ~id ~description) trees in
  let html =
    Layout.Default.layout
      ~title:"Reading Tree"
      [ p [ txt "Welcome to Reading Tree!" ]
      ; div tree_views
      ]
      request
  in
  Render.to_string html
