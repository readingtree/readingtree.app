type t =
  { title : string option
  ; book : string  (* Book _id *)
  ; description : string option
  ; children : t list
  ; tags : string list
  } [@@deriving yojson]
