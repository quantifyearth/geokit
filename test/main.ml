open Eio

let () =
  Eio_main.run @@ fun env ->
  let fs = Stdenv.fs env in
  Path.(
    with_open_in
      (fs / "/maps/pf341/JRC_TMF_AnnualChange_v1_2020_AFR_ID19_S10_E40.tif"))
  @@ fun file ->
  let tiff = Tiff.from_file file in
  let ifd = Tiff.ifd tiff in
  let keys = Tiff.Ifd.geo_key_directory ifd in
  Fmt.pr "AU %s\n"
    Tiff.Ifd.GeoKeys.(angular_units_to_string @@ angular_units keys);
  Fmt.pr "AU %s\n"
    Tiff.Ifd.GeoKeys.(
      (function RasterPixelIsArea -> "area" | _ -> "") @@ raster_type keys);
  Fmt.pr "SMA %.20f\n" Tiff.Ifd.GeoKeys.(semi_major_axis ifd keys);
  Fmt.pr "IF %.20f\n" Tiff.Ifd.GeoKeys.(inv_flattening ifd keys);
  Fmt.pr "GEOASCII %a\n" Fmt.(list string) Tiff.Ifd.(geo_ascii_params ifd);
  let pp_float ppf f = Fmt.pf ppf "%.20f" f in
  Fmt.pr "Pixel %a" Fmt.(array pp_float) (Tiff.Ifd.pixel_scale ifd)
