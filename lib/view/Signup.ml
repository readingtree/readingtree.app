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
      ~show_nav:false
      ~title:"Sign Up"
      [ form ~a:
          [ a_action "/signup"
          ; a_class [ "container"; "mt-5" ]
          ; a_style "max-width: 556px"
          ; a_method `Post
          ]
          [ h1
              ~a:[ a_class [ "display-3" ] ]
              [ txt "Sign up for Readingtree" ]
          ; div
              ~a:[ a_class [ "field-group" ] ]
              [ label
                  ~a:[ a_label_for "username" ]
                  [ txt "Username" ]
              ; input ~a:
                  [ a_input_type `Text
                  ; a_class [ "form-control" ]
                  ; a_name "name"
                  ; a_id "username"
                  ; a_value name
                  ; a_required ()
                  ] ()
              ]
          ; div
              ~a:[ a_class [ "field-group" ] ]
              [ label
                  ~a:[ a_label_for "email" ]
                  [ txt "Email" ]
              ; input ~a:
                  [ a_input_type `Email
                  ; a_class [ "form-control" ]
                  ; a_name "email"
                  ; a_id "email"
                  ; a_value email
                  ; a_required ()
                  ] ()
              ]
          ; div
              ~a:[ a_class [ "field-group" ] ]
              [ label
                  ~a:[ a_label_for "pass" ]
                  [ txt "Password" ]
              ; input ~a:
                  [ a_input_type `Password
                  ; a_class [ "form-control" ]
                  ; a_name "password"
                  ; a_id "pass"
                  ; a_required ()
                  ; Unsafe.string_attrib "aria-describedby" "pass-help"
                  ] ()
              ; div
                ~a:[ a_class [ "form-text" ]; a_id "pass-help" ]
                [ txt "Your password must be at least 8 characters, and include a special character." ]
              ]
          ; div
              ~a:[ a_class [ "field-group" ] ]
              [ label
                  ~a:[ a_label_for "confirm-pass" ]
                  [ txt "Confirm Password" ]
              ; input ~a:
                  [ a_input_type `Password
                  ; a_class [ "form-control" ]
                  ; a_name "password_confirm"
                  ; a_id "confirm-pass"
                  ; a_required ()
                  ] ()
              ]
          ; div [ Partial.Csrf.render request ]
          ; div
              [ button ~a:
                  [ a_class [ "btn"; "btn-primary"; "my-3" ] ]
                  [ txt "Sign Up" ]
              ]
          ; small
              [ txt "Have an account already? "
              ; a ~a:
                  [ a_href "/login" ]
                  [ txt "Click here to login" ]
              ; txt "."
              ]
          ; br ()
          ; small
              [ txt "Click "
              ; a
                  ~a:
                    [ a_href "/" ]
                  [ txt "here" ]
              ; txt " to go home."
              ]
          ; div ~a: [ a_class [ "text-danger" ] ] formatted_errors
          ; hr ()
          ; Partial.Login_agreement.render ()
          ]
      ]
      request
  in
  Render.to_string html
