open Eio
include Store_intf
module G = Geojsone.G

let or_fail = function Ok v -> v | Error (`Msg m) -> failwith m
let has_ext e (_, p) = Filename.extension p = e

module Make (M : Irmin_git.Maker) = struct
  module Branch_ptime = struct
    type t = Ptime.t

    let t =
      let t =
        Repr.(
          map string
            (fun s -> Ptime.of_rfc3339 s |> Result.get_ok |> fun (v, _, _) -> v)
            Ptime.to_rfc3339)
      in
      Repr.like ~compare:Ptime.compare t

    let pp_ref ppf t = Ptime.pp_rfc3339 () ppf t

    let of_ref s =
      Ptime.of_rfc3339 s
      |> Result.map (fun (v, _, _) -> v)
      |> Ptime.rfc3339_error_to_msg

    let main = Ptime.of_float_s 0. |> Option.get
    let is_valid _ = true
  end

  module Schema = Irmin_git.Schema.Make (M.G) (Metadata.V1) (Branch_ptime)
  module S = M.Make (Schema)

  type t = S.t

  let release t = match S.status t with `Branch b -> Some b | _ -> None
  let new_release src dst = S.clone ~src ~dst

  let releases t =
    S.Branch.list (S.repo t)
    |> List.stable_sort (Repr.unstage @@ Repr.compare S.Branch.t)

  let metadata_of_tiff path =
    Path.with_open_in path @@ fun file ->
    let tiff = Tiff.from_file file in
    let ifd = Tiff.ifd tiff in
    let width = Tiff.Ifd.width ifd in
    let height = Tiff.Ifd.height ifd in
    let geokeys = Tiff.Ifd.geo_key_directory ifd in
    let projection = Tiff.Ifd.GeoKeys.geo_citation ifd geokeys in
    let angular_units =
      Tiff.Ifd.GeoKeys.angular_units geokeys
      |> Tiff.Ifd.GeoKeys.angular_units_to_string
    in
    let meta =
      Metadata.Raw.V1.
        {
          width;
          length = height;
          compression = Tiff.Ifd.compression ifd |> Tiff.Ifd.compression_to_int;
          pixel_scale = Tiff.Ifd.pixel_scale ifd;
          tiepoint = Tiff.Ifd.tiepoint ifd;
          angular_units;
        }
    in
    Metadata.V1.v ~projection (`Tiff meta)

  let read_geojson path =
    let raw_json = Path.load path in
    let s = Geojsone_eio.src_of_flow (Eio.Flow.string_source raw_json) in
    Geojsone.Ezjsone.json_of_src s

  let geojson_kind_of_file path =
    let s =
      read_geojson path
      |> (function Ok v -> v | Error _ -> failwith "Failed to read GeoJSON!")
      |> Geojsone.G.of_json |> or_fail
    in
    match G.geojson s with
    | G.Geometry _ -> `Geometry
    | G.Feature _ -> `Feature
    | G.FeatureCollection _ -> `FeatureCollection

  let metadata_of_geojson path =
    let meta = Metadata.Raw.V1.{ kind = geojson_kind_of_file path } in
    (* As of GeoJSON 2008 this is the only projection supported *)
    Metadata.V1.v ~projection:"WGS 84" (`Geojson meta)

  let import _t _r dir =
    let files = Path.read_dir dir |> List.map Path.(( / ) dir) in
    let tifs =
      List.filter (fun v -> has_ext ".tif" v || has_ext ".tiff" v) files
    in
    let geojsons = List.filter (fun v -> has_ext ".geojson" v) files in
    let tif_imports = Fiber.List.map (fun p -> (p, metadata_of_tiff p)) tifs in
    let geojson_imports =
      Fiber.List.map (fun p -> (p, metadata_of_geojson p)) geojsons
    in
    let _imports = tif_imports @ geojson_imports in
    ()
end
