let hash_string str =
  str |> Digestif.SHA256.digest_string |> Digestif.SHA256.to_hex 
