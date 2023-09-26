open Lwt.Syntax
open Piaf
open Yojson

module Http = Client.Oneshot

type encoding_type = Json | Text

let ( >|= ) = Result.bind

let db_uri =
  match Sys.get_env_opt "COUCHDB_URI" with
  | Some uri -> uri
  | None -> failwith "COUCHDB_URI must be set."

let auth_credential =
  match ( Sys.get_env_opt "COUCHDB_USERNAME"
        , Sys.get_env_opt "COUCHDB_PASSWORD" )
  with
  | ( Some username
    , Some password ) -> Base64.encode_exn (username ^ ":" ^ password)
  | _ -> failwith "COUCHDB_PASSWORD or COUCHDB_USERNAME is not set."

let standard_headers =
  [ ("Content-Type", "application/json")
  ; ("Authorization", "Basic " ^ auth_credential) ]

let encode_response ~encoding res =
  if Status.is_successful res.status then
    match encoding with
    | Json -> Ok( YoJson.Safe.from_string @@ Body.to_string res.body)
    | Text -> Ok( Body.to_string res.body )
  else
    Error (Status.to_string res.status)

let find_list ~id =
  Http.post
    ~headers:standard_headers
    ~body:(Printf.sprintf {json|{_id: %s}|json} id)
    (db_uri ^ "/lists/_find")
  >|= encode_response ~encoding:Json
