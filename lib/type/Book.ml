type t =
  { author : string
  ; cover : string
  ; title : string
  ; isbn : string
  ; description : string
  } [@@deriving yojson]
