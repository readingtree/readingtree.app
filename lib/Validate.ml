let validate_name ~name () =
  let regex = Str.regexp "^[a-zA-Z0-9_-]+$" in
  String.length name >= 3 &&
  String.length name <= 25 &&
  (Str.string_match regex name 0) &&
  (String.lowercase_ascii name) <> "unknown" (** Reserved name for deleted records *)

let validate_password ~password () =
  let regex = Str.regexp {|^(?:(?=.*[a-z])(?:(?=.*[A-Z])(?=.*[\d\W])|(?=.*\W)(?=.*\d))|(?=.*\W)(?=.*[A-Z])(?=.*\d)).{8,}$|} in
  (Str.string_match regex password 0) && (String.length password >= 8)

let validate_email ~email () =
  let regex = Str.regexp "^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\\.[a-zA-Z0-9-]+)*$" in
  (String.length email > 4) && (Str.string_match regex email 0)

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
