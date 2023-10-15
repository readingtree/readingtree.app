let render ~id ~description =
  let open Tyxml.Html in
  div
    [ a
        ~a:[ a_class [ "text-primary" ]
           ; a_href ("/trees/" ^ id)
           ]
        [ txt description ]
    ]
