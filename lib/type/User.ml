type t =
  { username : string
  ; email : string
  ; books : string list
  ; role : string
  } [@@deriving yojson]
