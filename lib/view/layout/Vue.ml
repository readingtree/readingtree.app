let layout
    ~title:title_
    body_
    ?(init="vue.js")
    ?(description="Readingtree.app the best place to learn cool stuff")
    ?(keywords=[])
    ?(scripts=[])
    ?(styles=[])
    _request =
  let open Tyxml.Html in
  html
    ~a:[ a_lang "en" ]
    (head
       (title (txt title_))
       ([ meta ~a:[ a_charset "utf-8" ] ()
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
        ; script
            ~a:[ a_src "https://unpkg.com/vue@3/dist/vue.global.js" ]
            (txt "")
        ] @ (List.map (fun href -> link ~rel:[ `Stylesheet ] ~href ()) styles))
    )
    (body
       ~a:[ a_class [ "min-vh-100"; "min-vw-100" ] ]
       ([ Partial.Nav.render _request
        ; div
            ~a:[ a_class [ "w-100"; "h-100"; "m-md-2"; "m-sm-1" ]; a_id "app" ]
            body_
        ]
        @
        (List.map (fun s -> script ~a:[ a_src s ] (txt "")) scripts)
        @ [script ~a:[ a_src ("/static/js/" ^ init) ] (txt "")])
    )
