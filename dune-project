(lang dune 3.9)

(name geokit)

(generate_opam_files true)
(source (github quantifyearth/geokit))
(license MIT)
(authors "Patrick Ferris")
(maintainers "patrick@sirref.org")

(package
 (name geokit)
 (synopsis "Version control large geospatial datasets")
 (tags ("version control" "geospatial"))
 (description "Geokit is a tool for version controlling large geospatial datasets. Data is stored using ZFS with automatic metadata extraction of common geospatial formats.")
 (depends
   (eio (> 0.11))
   eio_main
   lwt_eio
   irmin
   geojsone
   ptime
   irmin-fs
   irmin-git))