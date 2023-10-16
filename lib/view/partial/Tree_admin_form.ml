let render ~id request =
  let open Tyxml.Html in
  div
    [
      form
        ~a:
          [ a_action ("/trees/" ^ id ^ "/books")
          ; a_method `Post
          ]
        [ div
            [ label [ txt "Id" ]
            ; input ~a:
                [ a_input_type `Text
                ; a_name "id"
                ; a_required ()
                ] ()
            ]
        ; div
            [ label [ txt "Title" ]
            ; input ~a:
                [ a_input_type `Text
                ; a_name "title"
                ; a_required ()
                ] ()
            ]
        ; div
            [ label [ txt "Cover" ]
            ; input ~a:
                [ a_input_type `Text
                ; a_name "cover"
                ; a_required ()
                ] ()
            ]
        ; div
            [ label [ txt "Author" ]
            ; input ~a:
                [ a_input_type `Text
                ; a_name "author"
                ; a_required ()
                ] ()
            ]
        ; div
            [ label [ txt "ISBN" ]
            ; input ~a:
                [ a_input_type `Text
                ; a_name "isbn"
                ; a_required ()
                ] ()
            ]
        ; div [ Csrf.render request ]
        ; div [
            button ~a:
              [ a_class [ "btn"; "btn-primary" ] ]
              [ txt "Add Book" ]
          ]
        ]
    ; form
        ~a:
          [ a_action ("/trees/" ^ id ^ "/edges")
          ; a_method `Post
          ]
        [ div
            [ label [ txt "From" ]
            ; input ~a:
                [ a_input_type `Text
                ; a_name "from"
                ; a_required ()
                ] ()
            ]
        ; div
            [ label [ txt "To" ]
            ; input ~a:
                [ a_input_type `Text
                ; a_name "to"
                ; a_required ()
                ] ()
            ]
        ; div [ Csrf.render request ]
        ; div [
            button ~a:
              [ a_class [ "btn"; "btn-primary" ] ]
              [ txt "Add Edge" ]
          ]
        ]
    ]
