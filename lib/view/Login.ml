let render
    ?(errors=[])
    request
  =
  let open Tyxml.Html in
  let referrer = Dream.query request "referrer" in
  let formatted_errors =
    List.map (fun (_, error) -> p ~a:[ a_class [ "text-danger" ] ] [ txt error ]) errors
  in
  let html =
    Layout.Default.layout
      ~title:"Log In"
      [ h1 [ txt "Log In" ]
      ; form ~a:
          [ a_action "/login"
          ; a_method `Post
          ]
          [ div
              [ label [ txt "Username" ]
              ; input ~a:
                  [ a_input_type `Text
                  ; a_name "name"
                  ; a_required ()
                  ] ()
              ]
          ; div
              [ label [ txt "Password" ]
              ; input ~a:
                  [ a_input_type `Password
                  ; a_name "password"
                  ; a_required ()
                  ] ()
              ]
          ; div [ Partial.Csrf.render request ]
          ; div [
              button ~a:
                [ a_class [ "btn"; "btn-primary" ] ]
                [ txt "Login" ]
            ]
          ; input ~a:
              [ a_input_type `Hidden
              ; a_name "referrer"
              ; a_value (match referrer with Some r -> r | None -> "/")
              ] ()
          ; div ~a:
              [ a_class [] ]
              formatted_errors
          ]
      ; p
          [ txt "Don't have an account? "
          ; a ~a:
              [ a_href "/signup" ]
              [ txt "Click here to sign up." ]
          ]
      ]
      request
  in
  Render.to_string html
