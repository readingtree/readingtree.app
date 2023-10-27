let render request =
  let open Tyxml.Html in
  div
    (Dream.flash_messages request
     |> List.map (fun (t, text) ->
         div
           ~a:[ a_class
                  [ "flex"
                  ; "alert"
                  ; "alert-" ^ t
                  ; "alert-dismissable"
                  ; "fade"
                  ; "show"
                  ; "justify-content-between"
                  ; "position-fixed"
                  ; "bottom-0"
                  ; "end-0"
                  ; "z-3"
                  ]
              ; a_role [ "alert" ]
              ]
           [ txt text
           ; button
               ~a:[ a_button_type `Button
                  ; a_class [ "btn-close" ]
                  ; Unsafe.string_attrib "data-bs-dismiss" "alert"
                  ; Unsafe.string_attrib "aria-label" "Close"
                  ]
               []
           ; script ~a:[ a_src "/static/js/alert.js" ] (txt "")
           ]
       )
    )
