type t =
  { author : string
  ; title : string
  ; isbn : string
  ; description : string
  } [@@deriving yojson]