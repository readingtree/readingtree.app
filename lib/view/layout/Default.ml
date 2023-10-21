let layout
      ~title:title_
      body_
      ?(show_nav=true)
      ?(description="Readingtree.app the best place to learn cool stuff")
      ?(keywords=[])
      ?(scripts=[])
      _request =
  let open Tyxml.Html in
  let flashes =
    Dream.flash_messages _request
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
          ]
      )
  in
  html
    ~a:[ a_lang "en" ]
    (head
       (title (txt title_))
       [ meta ~a:[ a_charset "utf-8" ] ()
       ; meta ~a:[ a_name "keywords"; a_content ("Readingtree.app " ^ description ^ " " ^ (List.fold_left (fun a b -> a ^ " " ^ b) "" keywords)) ] ()
       ; meta ~a:[ a_name "author"; a_content "The Reading Tree team" ] ()
       ; meta ~a:[ a_name "viewport"; a_content "width=device-width, initial-scale=1" ] ()
       ; link ~rel:[ `Stylesheet ] ~href:"/static/css/app.css" ()
       ; link
           ~a:[ a_integrity "sha384-T3c6CoIi6uLrA9TneNEoa7RxnatzjcDSCmG1MXxSR1GAsXEV/Dwwykc2MPK8M2HN"
              ; a_crossorigin `Anonymous ]
           ~rel:[ `Stylesheet ]
           ~href:"https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css"
           ()
       ; script
           ~a:[ a_src "https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"
              ; a_integrity "sha384-C6RzsynM9kWDrMNeT87bh95OGNyZPhcTNXj1NW7RuBCsyN/o0jlpcV8Qyq46cDfL"
              ; a_crossorigin `Anonymous ]
           (txt "")
       ]
    )
    (body
       ~a:[]
       ((if show_nav then [Partial.Nav.render _request] else []) @
        [ div flashes
        ; div
            ~a:[ a_class [ "m-md-2"; "m-sm-1" ] ]
            body_
        ; script ~a:[ a_src "/static/js/alert.js" ] (txt "")
        ; div @@ List.map (fun s -> script ~a:[ a_src s ] (txt "")) scripts
        ])
    )

