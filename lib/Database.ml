open Lwt.Syntax

type encoding_type = Json | Text
type couch_response =
  | Json_response of Yojson.Safe.t
  | Text_response of string

let ( >|= ) = Result.bind
let ( >>|= ) = fun a b ->
  match a with
  | Ok t -> b t
  | Error _ as e -> Lwt.return (e)

let db_uri =
  match Sys.getenv_opt "COUCHDB_URI" with
  | Some uri -> uri
  | None -> failwith "COUCHDB_URI must be set."

let auth_credential =
  match ( Sys.getenv_opt "COUCHDB_USER"
        , Sys.getenv_opt "COUCHDB_PASSWORD" )
  with
  | ( Some username
    , Some password ) -> Base64.encode_exn (username ^ ":" ^ password)
  | _ -> failwith "COUCHDB_PASSWORD or COUCHDB_USER is not set."

let standard_headers =
  [ ("Content-Type", "application/json")
  ; ("Accept", "application/json")
  ; ("Authorization", "Basic " ^ auth_credential) ]

exception Encoding_error of string
exception Request_error of string

let make_request =
  Http.request
    ~headers:standard_headers

let encode_response ~(encoding : encoding_type) response =
  let status = Hyper.status response in
  let+ body = Hyper.body response in
  if Hyper.is_successful status then
    match encoding with
    | Json ->
      begin
        match Json.from_string body with
        | Ok json -> Ok (Json_response json)
        | Error e -> Error (Encoding_error (Printexc.to_string e))
      end
    | Text -> Ok (Text_response body)
  else
    Error (Request_error ((Hyper.status_to_string status) ^ " " ^ body))

let create_db ~name () =
  let request = make_request ~meth:`PUT (db_uri ^ "/" ^ name) in
  let* response = Http.run request in
  response >>|= encode_response ~encoding:Json

let find_doc ~db ~id () =
  let request =
    let db_uri = (db_uri ^ "/" ^ db ^ "/" ^ id) in
    make_request
      ~meth:`GET
      db_uri
  in
  let* response = Http.run request in
  response >>|= encode_response ~encoding:Json

let find_docs ~db ?paginate ?(mango=`Assoc []) () =
  let mango =
    match paginate with
    | Some (page, size) ->
      begin
        match mango with
        | `Assoc m -> `Assoc (("limit", `Int size) :: ("skip", `Int (page * size)) :: m)
        | _ -> raise @@ Failure ("Mango must be a `Assoc.")
      end
    | None -> mango
  in
  let request =
    make_request
      ~body:(Json.to_string mango)
      ~meth:`POST
      (db_uri ^ "/" ^ db ^ "/_find")
  in
  let* response = Http.run request in
  response >>|= encode_response ~encoding:Json

let find_all_docs ~db ~paginate:(page, size) () =
  let request =
    make_request
      ~meth:`GET
      (db_uri ^ "/" ^ db ^ "/_all_docs" ^ (Printf.sprintf "?limit=%d&skip=%d&include_docs=true" page size))
  in
  let* response = Http.run request in
  let+ encoded_response = response >>|= encode_response ~encoding:Json in
  match encoded_response with
  | Ok (Json_response json) ->
    begin
      match Json.member "rows" json with
      | Ok (`List rows) ->
        let docs =
          List.filter_map
            (fun row -> match Json.member "doc" row with Ok json -> Some json | _ -> None)
            rows
        in
        Ok (Json_response (`Assoc ([("docs", `List docs)])))
      | Ok _ -> Error (Failure "Something went wrong encoding in find_all_docs.")
      | Error _ as e -> e
    end
  | _ as e -> e

(** Creates or saves a document, id is required.
    You should probably use [create_doc] if you want to create a new document. *)
let save_doc ~db ~id ~doc () =
  let request =
    make_request
      ~meth:`PUT
      ~body:(Json.to_string doc)
      (db_uri ^ "/" ^ db ^ "/" ^ id)
  in
  let* response = Http.run request in
  response >>|= encode_response ~encoding:Json

(** Creates a new document, with a random UUID.
    This simply just wraps [save_doc] and handles ID generation for you. *)
let create_doc ~db ~doc () =
  let+ response = save_doc ~db ~id:(Ulid.ulid ()) ~doc () in
  Result.bind response (fun _ -> Ok ())

let delete_doc ?rev ~db ~id () =
  let query = (
    match rev with
    | Some revision -> Printf.sprintf "?rev=%s" revision
    | None -> ""
  )
  in
  let request =
    make_request
      ~meth:`DELETE
      (db_uri ^ "/" ^ db ^ "/" ^ id ^ query)
  in
  let* response = Http.run request in
  response >>|= encode_response ~encoding:Json
