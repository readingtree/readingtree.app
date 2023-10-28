let render
    ~user_id
    ()
  =
  let open Tyxml.Html in
  form
    ~a:[ a_method `Post
       ; a_action ("/profile/" ^ user_id ^ "/change-password")
       ; a_style "max-width: 556px"
       ]
    [ h2 [ (txt "Change Password" ) ]
    ; div
        ~a:[ a_class [ "form-group" ] ]
        [
          label
            ~a:[ a_label_for "new-password" ]
            [ txt "New Password" ]
        ; input ~a:
            [ a_input_type `Text
            ; a_class [ "form-control" ]
            ; a_id "new-password"
            ; a_name "password"
            ; a_required ()
            ] ()
        ]
    ; div
        ~a:[ a_class [ "form-group" ] ]
        [
          label
            ~a:[ a_label_for "confirm-new-password" ]
            [ txt "Confirm Password" ]
        ; input ~a:
            [ a_input_type `Text
            ; a_class [ "form-control" ]
            ; a_id "confirm-new-password"
            ; a_name "confirm-password"
            ; a_required ()
            ] ()
        ]
    ; button
        ~a:[ a_class [ "btn"; "btn-success" ]
           ; a_button_type `Submit
           ]
        [ (txt "Change Password") ]
    ]
