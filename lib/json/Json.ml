module S = Yojson.Safe
module U = Yojson.Safe.Util

let member m json =
  try
    Ok (U.member m json)
  with
    e -> Error e

let to_string = S.to_string

let from_string str =
  try
    Ok (S.from_string str)
  with
    e -> Error e

let pp json = Format.asprintf "Parsed to %a" Yojson.Safe.pp json
