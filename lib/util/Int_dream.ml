let get_page_parameters request =
  let size =
    match Dream.query request "size" with
    | Some size ->
      begin
        match int_of_string_opt size with
        | Some i -> i
        | None -> 10
      end
    | None -> 10
  in
  let page =
    match Dream.query request "page" with
    | Some page ->
      begin
        match int_of_string_opt page with
        | Some i -> i
        | None -> 0
      end
    | None -> 0
  in
  (size, page)
