(lang dune 3.6)

(name readingtree)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "The Reading Tree Team")

(maintainers "Rawley Fowler")

(license LICENSE)

(documentation https://github.com/readingtree/readingtree)

(package
 (name readingtree)
 (synopsis "A Dream web application that backs readingtree")
 (description "A longer description")
 (depends
   ocaml
   dune
   dream
   lwt
   cmdliner
   yojson
   ulid
   ppx_deriving_yojson
   base64
   digestif
   hyper
   tyxml
   re2
   ptime)
 (tags
  (web application reading)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
