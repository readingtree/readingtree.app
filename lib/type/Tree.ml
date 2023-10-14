type t =
  { _id : string
  ; _rev : string
  ; typ : string
  ; book : Book.t list
  ; description : string option
  ; children : t list
  ; tags : string list
  } [@@deriving yojson]
