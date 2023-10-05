type t =
  { title : string option
  ; book : string  (* Book _id *)
  ; description : string option
  ; children : t list
  ; tags : string list
  } [@@deriving yojson]

let number_of_children tree =
  let rec aux tree =
    let count = List.fold_left (fun acc _ -> acc + 1) 0 tree.children in
    List.fold_left (fun acc c -> acc + (count + aux c)) 0 tree.children
  in
  aux tree
