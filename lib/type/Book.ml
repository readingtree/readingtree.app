type t =
  { author : string
  ; typ : string
  ; title : string
  ; isbn : string
  ; description : string
  } [@@deriving yojson]
