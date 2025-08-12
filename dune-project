(lang dune 3.19)

(name nextmeet)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name <author@example.com>")

(maintainers "Maintainer Name <maintainer@example.com>")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name nextmeet)
 (synopsis "Find upcoming Google Meet links from Google Calendar")
 (description "A command-line utility that finds Google Meet links for meetings starting within ±10 minutes")
 (depends 
  ocaml
  dune
  lwt
  cohttp-lwt-unix
  tls-lwt
  yojson
  ptime
  uri
  base64
  (alcotest :with-test)
  (lwt :with-test))
 (tags
  ("calendar" "google" "meet" "cli")))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
