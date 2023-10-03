(** Utils that dont really fit in Util.ml *)
let _get_page_parameters request =
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

(** Render the index page. *)
let index_view_handler request = Dream.html @@ View.Index.render request
let trees_list_view_handler request =
  let (page, size) = _get_page_parameters request in
  match%lwt Database.find_docs ~db:"trees" ~mango:(`Assoc [("limit", `Int size); ("skip", `Int (size * page))]) () with
  | Ok (Json_response (json)) ->
    begin
      match Json.member "rows" json with
      | Ok (`List trees) ->
        let trees = List.filter_map (fun tree -> match Type.Tree.of_yojson tree with Ok t -> Some t | Error _ -> None) trees in
        Dream.html @@ View.Trees.render ~trees request
      | Ok _ | Error _ -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render request
    end
  | Ok (Text_response _) -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render request
  | Error exn -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render ~exn request

(** Get all books by ids, we want this instead of a get all books because we'll probably have a crap ton of books. *)
let get_books_handler request =
  let (page, size) = _get_page_parameters request in
  let ids = List.map (fun s -> `String s) @@ Dream.queries request "ids" in
  if ids = [] then Dream.json "[]"
  else
    match%lwt Database.find_docs
                ~db:"books"
                ~mango:(`Assoc [("keys", `List ids); ("limit", `Int size); ("skip", `Int (size * page))])
                ()
    with
    | Ok (Json_response books) -> books |> Json.to_string |> Dream.json
    | Ok (Text_response _ ) -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render request
    | Error exn -> Dream.html ~status:`Internal_Server_Error @@ View.ServerError.render ~exn request

(** Get a list of trees, paginated by ?size and ?page. *)
let get_trees_paginated_handler request =
  let (page, size) = _get_page_parameters request in
  let skip = page * size in
  let mango =
    `Assoc (
      [ ("limit", `Int size)
      ; ("skip", `Int skip)
      ]
    )
  in
  match%lwt Database.find_docs ~db:"trees" ~mango () with
  | Ok (Json_response json) -> Dream.json @@ Json.to_string json
  | Error exn ->
    Dream.html ~status:`Internal_Server_Error
    @@ View.ServerError.render ~exn request
  | _ -> Dream.empty `Bad_Request
