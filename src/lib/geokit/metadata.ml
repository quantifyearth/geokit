(* We build-on versioning support from the get-go *)
module Raw = struct
  module V1 = struct
    type geojson = { kind : [ `Geometry | `Feature | `FeatureCollection ] }
    [@@deriving irmin]

    type tiff = {
      width : int;
      length : int;
      compression : int;
      pixel_scale : float array;
      tiepoint : float array;
      angular_units : string;
    }
    [@@deriving irmin]

    type t = {
      projection : string;
      details : [ `Geojson of geojson | `Tiff of tiff ];
    }
    [@@deriving irmin ~pre_hash]

    let merge = Irmin.Merge.(default t)
    let v ~projection details = { projection; details }
  end

  type t = V1 of V1.t [@@deriving irmin]

  let to_v1 = function V1 v1 -> v1
  let pre_hash = function V1 v1 -> V1.pre_hash v1
  let t = Irmin.Type.like ~pre_hash t

  let merge =
    let promise x = Irmin.Merge.promise x in
    let upgrade = Fun.id in
    let wrap_v1 v = V1 v in
    let rec f ~(old : t Irmin.Merge.promise) x y =
      match (old (), x, y) with
      | Ok (Some (V1 old)), V1 x, V1 y ->
          Irmin.Merge.f V1.merge ~old:(promise old) x y |> Result.map wrap_v1
      | _ ->
          let old =
            match old () with
            | Ok None -> fun () -> Ok None
            | Ok (Some old) -> promise (upgrade old)
            | Error e -> fun () -> Error e
          in
          f ~old (upgrade x) (upgrade y)
    in
    Irmin.Merge.seq [ Irmin.Merge.default t; Irmin.Merge.v t f ]
end

type 'a view = { payload : 'a; raw : Raw.t }

let version v = match v.raw with V1 _ -> 1

module V1 = struct
  type t = Raw.V1.t view

  let of_raw raw =
    let payload = Raw.to_v1 raw in
    { payload; raw }

  let to_raw t = t.raw
  let t = Irmin.Type.map Raw.t of_raw to_raw

  let v ~projection details : t =
    let v = Raw.V1.v ~projection details in
    { payload = v; raw = V1 v }

  let version = version
  let merge = Irmin.Merge.(option @@ like t Raw.merge to_raw of_raw)
end
