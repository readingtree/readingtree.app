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

let find_doc ~db ?id ?mango () =
  let db_uri = (db_uri ^ "/" ^ db ^ "/_find") in
  let request =
    match id with
    | Some id ->
      make_request
        ~body:(Json.to_string (`Assoc [("_id", `String id)]))
        ~meth:`POST
        db_uri
    | None ->
      begin
        match mango with
        | Some mango ->
          make_request
            ~body:(Json.to_string mango)
            ~meth:`POST
            db_uri
        | None ->
          make_request
            ~meth:`GET
            db_uri
      end
  in
  let* response = Http.run request in
  response >>|= encode_response ~encoding:Json

let find_docs ~db ~mango () =
  let actual_mango =
    match mango with
    | `Assoc m -> Ok(`Assoc (("include_docs", `Bool true) :: m))
    | _ -> Error(Failure "Invalid mango passed.")
  in
  match actual_mango with
  | Ok mango ->
    let request =
      make_request
        ~body:(Json.to_string mango)
        ~meth:`POST
        (db_uri ^ "/" ^ db ^ "/_all_docs")
    in
    let* response = Http.run request in
    response >>|= encode_response ~encoding:Json
  | Error _ as e -> Lwt.return e

let save_doc ~db ~id ~doc () =
  let request =
    make_request
      ~meth:`PUT
      ~body:(Json.to_string doc)
      (db_uri ^ "/" ^ db ^ "/" ^ id)
  in
  let* response = Http.run request in
  response >>|= encode_response ~encoding:Json

(** Creates a new document, with a random UUID. *)
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
