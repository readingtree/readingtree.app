let render
    ~user_id
    ~num_books
    ~last_read_time
    ~name
    request
  =
  let open Tyxml.Html in
  let is_current_user =
    match Dream.session_field request "user" with
    | Some id -> user_id = id
    | None -> false
  in
  let html =
    Layout.Default.layout
      ~title:(name ^ "'s profile")
      [ div
          ~a:[ a_class [ "container" ] ]
          [ div
              [ h1 [ (txt name) ] ]
          ; div
              [ strong [ (txt "Books Read") ]
              ; txt (": " ^ name)
              ]
          ; div [ strong [ (txt "Last Read Time") ]
                ; txt (": " ^ last_read_time)
                ]
          ; div [ strong [ (txt "Total Books Read") ]
                ; txt (": " ^ (string_of_int num_books))
                ]
          ; (if not is_current_user then div []
             else Partial.Change_password_form.render ~user_id request)
          ]
      ]
      request
  in
  Render.to_string html
