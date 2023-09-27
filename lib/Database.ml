open Lwt.Syntax
open Piaf

module Http = Client.Oneshot

type encoding_type = Json | Text
type couch_response =
  | Json_response of Yojson.Safe.t
  | Text_response of string

let ( >|= ) = Result.bind
let ( >>|= ) = fun a b ->
  match a with
  | Ok t -> b t
  | Error e -> Lwt.return (Error ( Error.to_string e ))

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

let encode_response ~(encoding : encoding_type) (res : Piaf.Response.t) =
  if Status.is_successful res.status then
    let+ body = Body.to_string res.body in
    Result.map_error Error.to_string (
        body >|=
          fun b ->
          Ok( match encoding with
              | Json -> Json_response( Yojson.Safe.from_string b )
              | Text -> Text_response( b )
            )
      )
  else
    Lwt.return ( Error(Status.to_string res.status) )

let create_db ~name =
  let* response =
    Http.put
      ~headers:standard_headers
      (Uri.of_string (db_uri ^ "/" ^ name))
  in
  response >>|= encode_response ~encoding:Json

let find_doc ~db ~id =
  let* response =
    Http.post
      ~headers:standard_headers
      ~body:(Body.of_string @@ Printf.sprintf {json|{_id: %s}|json} id)
      (Uri.of_string (db_uri ^ "/" ^ db ^ "/_find"))
  in
  response >>|= encode_response ~encoding:Json

let save_doc ~db ~doc =
  let* response =
    Http.put
      ~headers:standard_headers
      ~body:(Body.of_string @@ Yojson.Safe.to_string doc)
      (Uri.of_string (db_uri ^ "/" ^ db))
  in
  response >>|= encode_response ~encoding:Json
