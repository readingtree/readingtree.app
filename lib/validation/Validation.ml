let name_regex = Re2.create_exn "^[a-zA-Z0-9_-]+$"
let email_regex = Re2.create_exn "^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)*$"
let password_regex = Re2.create_exn {|[!|@|#|$|%|^|&|\*|(|)|\[|\]|\"|:|;|'|<|>|\/|\\|,|.|`|~]|}

let validate_name ~name () =
  String.length name >= 3 &&
  String.length name <= 25 &&
  (Re2.matches name_regex name) &&
  (String.lowercase_ascii name) <> "unknown" (** Reserved name for deleted records *)

let validate_password ~password () =
  (String.length password >= 8) && (Re2.matches password_regex password)

let validate_email ~email () =
  (String.length email > 4) && (Re2.matches email_regex email)

let validate_sign_up ~name ~email ~password ~confirm () =
  let errors = ref [] in
  if not @@ validate_password ~password () then
    errors := ("password", "Your password is not complex enough. (8 characters and at least one special character.)") :: !errors;
  if not (password = confirm) then
    errors := ("confirm", "Your passwords do not match.") :: !errors;
  if not @@ validate_name ~name () then
    errors := ("name", "Your name is invalid. (3 - 25 characters, no unicode characters.)") :: !errors;
  if not @@ validate_email ~email () then
    errors := ("email", "Your email is not a valid email.") :: !errors;
  !errors

let validate_field_unique ~db field value =
  let open Lwt.Syntax in
  let+ json = Database.find_docs ~db ~mango:(`Assoc [("fields", `List [`String "_id"]); ("selector", `Assoc [(field, value)])]) () in
  match json with
  | Ok json ->
    begin
      match Json.member "docs" json with
      | Ok (`List []) -> Ok true
      | Ok _ -> Ok false
      | Error _ as e -> e
    end
  | Error _ as e -> e
