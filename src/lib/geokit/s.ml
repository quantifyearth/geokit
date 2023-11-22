type id = string

module type Snapshot_store = sig
  type t

  val root : t -> string
  (** [root t] returns the root of the store. *)

  val df : t -> float
  (** [df t] returns the percentage of free space in the store. *)

  val build :
    t -> ?base:id -> id:id -> (string -> (unit, 'e) result) -> (unit, 'e) result
  (** [build t ~id fn] runs [fn tmpdir] to add a new item to the store under
      key [id]. On success, [tmpdir] is saved as [id], which can be used
      as the [base] for further builds, until it is expired from the cache.
      On failure, nothing is recorded and calling [build] again will make
      another attempt at building it.
      The builder will not request concurrent builds for the same [id] (it
      will handle that itself). It will also not ask for a build that already
      exists (i.e. for which [result] returns a path).
      @param base Initialise [tmpdir] as a clone of [base]. *)

  val delete : t -> id -> unit
  (** [delete t id] removes [id] from the store, if present. *)

  val result : t -> id -> string option
  (** [result t id] is the path of the build result for [id], if present. *)

  val log_file : t -> id -> string
  (** [log_file t id] is the path of the build logs for [id]. The file may
      not exist if the build has never been run, or failed. *)

  val state_dir : t -> string
  (** [state_dir] is the path of a directory which can be used to store mutable
      state related to this store (e.g. an sqlite3 database). *)
end
