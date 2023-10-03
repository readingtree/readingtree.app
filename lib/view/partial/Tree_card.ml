module Tree = Type.Tree

let render (tree : Tree.t) =
  let open Tyxml.Html in
  div [ txt (match tree.title with Some s -> s | None -> "Unnamed") ]

