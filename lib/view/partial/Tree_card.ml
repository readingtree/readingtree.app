let render ~id ~description ~num_nodes =
  let open Tyxml.Html in
  div
    [ a
        ~a:[ a_class [ "text-primary" ]
           ; a_href ("/trees/" ^ id)
           ]
        [ txt description ]
    ; txt (" - " ^ (string_of_int num_nodes) ^ " nodes.")
    ]
