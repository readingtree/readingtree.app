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
      ~show_nav:false
      ~title:"Log In"
      [ form ~a:
          [ a_action "/login"
          ; a_method `Post
          ; a_style "max-width: 556px"
          ; a_class [ "container"; "mt-5" ]
          ]
          [ h1 ~a:[ a_class [ "display-3" ] ] [ txt "Log in to Readingtree" ]
          ; div
              ~a:[ a_class [ "form-group" ] ]
              [
                label
                  ~a:[ a_label_for "username" ]
                  [ txt "Username" ]
              ; input ~a:
                  [ a_input_type `Text
                  ; a_class [ "form-control" ]
                  ; a_id "username"
                  ; a_name "name"
                  ; a_required ()
                  ] ()
              ]
          ; div
              ~a:[ a_class [ "form-group" ] ]
              [
                label
                  ~a:[ a_label_for "pass" ]
                  [ txt "Password" ]
              ; input ~a:
                  [ a_input_type `Password
                  ; a_class [ "form-control" ]
                  ; a_id "pass"
                  ; a_name "password"
                  ; a_required ()
                  ] ()
              ]
          ; div [ Partial.Csrf.render request ]
          ; div [
              button ~a:
                [ a_class [ "btn"; "btn-primary"; "my-3" ] ]
                [ txt "Login" ]
            ]
          ; input ~a:
              [ a_input_type `Hidden
              ; a_name "referrer"
              ; a_value (match referrer with Some r -> r | None -> "/")
              ] ()
          ; div
              formatted_errors
          ; small
              [ txt "Don't have an account? "
              ; a ~a:
                  [ a_href "/signup" ]
                  [ txt "Click here to sign up" ]
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
          ; hr ()
          ; small
              [ txt "By logging you, you accept our "
              ; a ~a:
                  [ a_href "/privacy" ]
                  [ txt "privacy policy" ]
              ; txt " and our "
              ; a ~a:
                  [ a_href "/tos" ]
                  [ txt "terms of service" ]
              ; txt "."
              ]
          ]
      ]
      request
  in
  Render.to_string html
