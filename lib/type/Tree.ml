type t =
  { book : Book.t
  ; description : string option
  ; children : t list
  ; tags : string list
  } [@@deriving yojson]
