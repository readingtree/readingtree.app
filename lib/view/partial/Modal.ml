let render
  ~id
  ~title:_title
  ~content:_content
  ~footer:_footer =
  let open Tyxml.Html in
  div
    ~a:[ a_class [ "modal" ]
       ; a_id id
       ; Unsafe.string_attrib "aria-labelledby" id
       ; Unsafe.string_attrib "tabindex" "-1"
       ]
    [ div
        ~a:[ a_class [ "modal-dialog" ] ]
        [ div
            ~a:[ a_class [ "modal-content" ] ]
            [ div
                ~a:[ a_class [ "modal-header" ] ]
                [ h5
                    ~a:[ a_class [ "modal-title" ] ]
                    [ txt _title ]
                ; button
                    ~a:[ a_class [ "btn-close" ]
                       ; a_button_type `Button
                       ; Unsafe.string_attrib "data-bs-dismiss" "modal"
                       ; Unsafe.string_attrib "aria-label" "Close"
                       ]
                    []
                ]
            ; div
                ~a:[ a_class [ "modal-body" ] ]
                _content
            ; div
                ~a:[ a_class [ "modal-footer" ] ]
                _footer
            ]
        ]
    ]
