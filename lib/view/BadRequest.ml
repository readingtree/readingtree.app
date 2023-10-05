let render request =
  let open Tyxml.Html in
  let html =
    Layout.Default.layout
      ~title:"400 Bad Request"
      [ h1 [ txt "400 Bad Request" ]
      ; p
          [ txt "Something went wrong processing your request. Please try again."]
      ]
      request
  in
  Render.to_string html
