let render ~trees request =
  let open Tyxml.Html in
  let tree_views = List.map Partial.Tree_card.render trees in
  let html =
    Layout.Default.layout
      ~title:"Reading Tree"
      [ p [ txt "Welcome to Reading Tree!" ]
      ; div tree_views
      ; Partial.Tree_card.render { title = Some "foo"; book = "Book"; description = None; children = [{ title = Some "foo"; book = "Book"; description = None; children = []; tags = ["asdas"] }]; tags = ["oo"] }
      ]
      request
  in
  Render.to_string html
