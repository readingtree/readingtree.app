let render () =
  let open Tyxml.Html in
  small
    [ txt "By logging in or signing up, you accept our "
    ; a ~a:
        [ a_href "/privacy" ]
        [ txt "privacy policy" ]
    ; txt " and our "
    ; a ~a:
        [ a_href "/tos" ]
        [ txt "terms of service" ]
    ; txt "."
    ]
