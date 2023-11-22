module Raw : sig
  module V1 : sig
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
  end

  type t
end

type 'a view = { payload : 'a; raw : Raw.t }

val version : _ view -> int

module V1 : sig
  type t = Raw.V1.t view

  val v :
    projection:string ->
    [ `Geojson of Raw.V1.geojson | `Tiff of Raw.V1.tiff ] ->
    t
  (** [v kind projection] is a new metadata value. *)

  val version : t -> int

  include Irmin.Contents.S with type t := t
end
