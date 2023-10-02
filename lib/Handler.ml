let index_handler request = Dream.html @@ View.Index.render request

let get_trees_paginated_handler request =
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
  let skip = page * size in
  let mango =
    `Assoc (
      [ ("limit", `Int size)
      ; ("skip", `Int skip)
      ; ("include_docs", `Bool true)
      ]
    )
  in
  match%lwt Database.find_docs ~db:"trees" ~mango () with
  | Ok (Json_response json) -> Dream.json @@ Json.to_string json
  | Error exn ->
    Dream.html ~status:`Internal_Server_Error
    @@ View.ServerError.render ~exn request
  | _ -> Dream.empty `Bad_Request

