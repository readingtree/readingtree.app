let render request =
  let open Tyxml.Html in
  let nav_list =
    match Dream.session_field request "user" with
    | Some _ ->
      let user_id = Option.get @@ Dream.session_field request "user" in
      [ li
          ~a:[ a_class [ "nav-item" ] ]
          [ a ~a:[ a_href "/trees" ] [ txt "Trees" ] ]
      ; li
          ~a:[ a_class [ "nav-item"; "ms-md-2" ] ]
          [ a ~a:[ a_href ("/profile/" ^ user_id) ] [ txt "Profile" ] ]
      ; li
          ~a:[ a_class [ "nav-item"; "ms-md-2" ] ]
          [ a ~a:[ a_href "/logout" ] [ txt "Logout" ] ]
      ]
    | None ->
      [ li
          ~a:[ a_class [ "nav-item" ] ]
          [ a ~a:[ a_href "/trees" ] [ txt "Trees" ] ]
      ; li
          ~a:[ a_class [ "nav-item"; "ms-md-2" ] ]
          [ a ~a:[ a_href "/login" ] [ txt "Login" ] ]
      ; li
          ~a:[ a_class [ "nav-item"; "ms-md-2" ] ]
          [ a ~a:[ a_href "/signup" ] [ txt "Sign-up" ] ]
      ]
  in
  nav
    ~a:[ a_class [ "navbar"; "navbar-expand-lg"; "navbar-light"; "bg-light" ] ]
    [
      div
        ~a:[ a_class [ "container-fluid" ] ]
        [ a ~a:[ a_class [ "navbar-brand"; "display-4" ]; a_href "/" ] [ txt "Reading Tree"]
        ; button
            ~a:[ a_class [ "navbar-toggler" ]
               ; Unsafe.string_attrib "type" "button"
               ; Unsafe.string_attrib "data-bs-toggle" "collapse"
               ; Unsafe.string_attrib "data-bs-target" "#navbar-supported-content"
               ; Unsafe.string_attrib "aria-controls" "navbar-supported-content"
               ; Unsafe.string_attrib "aria-expanded" "false"
               ; Unsafe.string_attrib "aria-label" "Toggle navigation"
               ]
            [ span ~a:[ a_class [ "navbar-toggler-icon" ] ] [] ]
        ; div
            ~a:[ a_class [ "collapse"; "navbar-collapse" ]
               ; a_id "navbar-supported-content"
               ]
            [ ul
                ~a:[ a_class [ "navbar-nav" ] ]
                nav_list
            ]
        ]
    ]
