module Tree = Type.Tree

let render (tree : Tree.t) =
  let open Tyxml.Html in
  div
    [ a
        ~a:[ a_class [ "text-primary" ]
           ; a_href ("/trees/" ^ tree._id)
           ]
        [ txt (match tree.title with Some s -> s | None -> "Unnamed") ]
    ]
