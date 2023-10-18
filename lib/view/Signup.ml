let render
    ?(name="")
    ?(email="")
    ?(errors=[])
    request =
  let open Tyxml.Html in
  let formatted_errors =
    List.map
      (fun (_, value) -> p ~a:[ a_class [ "text-danger" ] ] [ txt value ])
      errors
  in
  let html =
    Layout.Default.layout
      ~title:"Sign Up"
      [ h1 [ txt "Sign up" ]
      ; form ~a:
          [ a_action "/signup"
          ; a_method `Post
          ]
          [ div
              ~a:[ a_class [ "field-group" ] ]
              [ label [ txt "Username" ]
              ; input ~a:
                  [ a_input_type `Text
                  ; a_name "name"
                  ; a_value name
                  ; a_required ()
                  ] ()
              ]
          ; div
              ~a:[ a_class [ "field-group" ] ]
              [ label [ txt "Email" ]
              ; input ~a:
                  [ a_input_type `Email
                  ; a_name "email"
                  ; a_value email
                  ; a_required ()
                  ] ()
              ]
          ; div
              ~a:[ a_class [ "field-group" ] ]
              [ label [ txt "Password" ]
              ; input ~a:
                  [ a_input_type `Password
                  ; a_name "password"
                  ; a_required ()
                  ] ()
              ]
          ; div
              ~a:[ a_class [ "field-group" ] ]
              [ label [ txt "Confirm Password" ]
              ; input ~a:
                  [ a_input_type `Password
                  ; a_name "password_confirm"
                  ; a_required ()
                  ] ()
              ]
          ; div [ Partial.Csrf.render request ]
          ; div
              [ button ~a:
                  [ a_class [ "btn"; "btn-primary" ] ]
                  [ txt "Sign Up" ]
              ]
          ; div ~a: [ a_class [ "text-danger" ] ] formatted_errors
          ]
      ; p
          [ txt "Already have an account? "
          ; a ~a:
              [ a_href "/login" ]
              [ txt "Click here to login." ]
          ]
      ]
      request
  in
  Render.to_string html
