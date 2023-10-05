module Tree = Type.Tree

let render (tree : Tree.t) =
  let open Tyxml.Html in
  div
    [ txt (match tree.title with Some s -> s | None -> "Unnamed")
    ; txt (string_of_int @@ (1 + Tree.number_of_children tree))
    ]
