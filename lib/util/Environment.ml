let in_development =
  Option.is_none @@ Sys.getenv_opt "PRODUCTION"
