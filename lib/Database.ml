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
  match ( Sys.getenv_opt "COUCHDB_USERNAME"
        , Sys.getenv_opt "COUCHDB_PASSWORD" )
  with
  | ( Some username
    , Some password ) -> Base64.encode_exn (username ^ ":" ^ password)
  | _ -> failwith "COUCHDB_PASSWORD or COUCHDB_USERNAME is not set."

let standard_headers =
  [ ("Content-Type", "application/json")
  ; ("Accept", "application/json")
  ; ("Authorization", "Basic " ^ auth_credential) ]

exception Encoding_error of string

let make_request =
  Http.request
    ~headers:standard_headers

let encode_response ~(encoding : encoding_type) response =
  let status = Hyper.status response in
  if Hyper.is_successful status then
    let+ body = Hyper.body response in
    match encoding with
    | Json ->
       begin
         match Json.from_string body with
         | Ok json -> Ok (Json_response json)
         | Error e -> Error (Encoding_error (Printexc.to_string e))
       end
    | Text -> Ok (Text_response body)
  else
    Lwt.return (Error (Encoding_error (Hyper.status_to_string status)))

let create_db ~name =
  let request = make_request ~meth:`PUT (db_uri ^ "/" ^ name) in
  let* response = Http.run request in
  response >>|= encode_response ~encoding:Json

let find_doc ~db ~id =
  let request =
    make_request
      ~body:(Json.to_string (`Assoc [("_id", `String id)]))
      ~meth:`POST
      (db_uri ^ "/" ^ db ^ "/_find")
  in
  let* response = Http.run request in
  response >>|= encode_response ~encoding:Json

let save_doc ~db ~doc =
  let request =
    make_request
      ~meth:`PUT
      ~body:(Json.to_string doc)
      (db_uri ^ "/" ^ db)
  in
  let* response = Http.run request in
  response >>|= encode_response ~encoding:Json
