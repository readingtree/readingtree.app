let layout
      ~title:title_
      body_
      ?(description="Readingtree.app the best place to learn cool stuff")
      ?(keywords=[])
      ?(scripts=[])
      _request =
  let open Tyxml.Html in
  html
    ~a:[ a_lang "en" ]
    (head
       (title (txt title_))
       [ meta ~a:[ a_charset "utf-8" ] ()
       ; meta ~a:[ a_name "keywords"; a_content ("Readingtree.app " ^ description ^ " " ^ (List.fold_left (fun a b -> a ^ " " ^ b) "" keywords)) ] ()
       ; meta ~a:[ a_name "author"; a_content "The Reading Tree team" ] ()
       ; meta ~a:[ a_name "viewport"; a_content "width=device-width, initial-scale=1" ] ()
       ; link ~rel:[ `Stylesheet ] ~href:"/static/css/layout.css" ()
       ]
    )
    (body
       ~a:[]
       [ div body_
       ; div @@ List.map (fun s -> script ~a:[a_src s] (txt "")) scripts
       ]
    )

