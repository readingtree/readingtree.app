let to_string html =
  Format.asprintf "%a" (Tyxml.Html.pp ()) html
