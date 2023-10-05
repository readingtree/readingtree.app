let render ?(exn=Failure "Unknown error") request =
  let open Tyxml.Html in
  let html =
    Layout.Default.layout
      ~title:"500 Internal Server Error"
      [ h1 [ txt "We ran into an error." ]
      ; p
          (if Util.Environment.in_development then [ txt (Printexc.to_string exn) ]
           else [ txt "Internal server error please try again later."])
      ]
      request
  in
  Render.to_string html
