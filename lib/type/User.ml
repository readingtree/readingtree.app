type t =
  { username : string
  ; email : string
  ; books : string list
  } [@@deriving yojson]
