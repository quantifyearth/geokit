module type S = sig
  type t

  val release : t -> Ptime.t option
  (** [release t] is essentially the current branch of the store which corresponds to
      the time when the data was downloaded/imported. It might return [None] if the current
      Irmin store is checked out in to a commit or nothing. *)

  val releases : t -> Ptime.t list
  (** All of the releases in the store, the list is sorted newests to oldest. *)

  val new_release : t -> Ptime.t -> t
  (** [new_release t p] creates a new branch using [p] from [t]. *)

  val import : t -> Ptime.t -> Eio.Fs.dir_ty Eio.Path.t -> unit
  (** [import t p dir] will import all of the files in the directory [dir] (not recursively)
      into the store by first creating a new branch using [p] from [t], syncing the underlying
      ZFS store and then populating the Git store and creating a fresh spatial index for the branch. *)
end

module type Maker = functor (_ : Irmin_git.Maker) -> sig
  include S
end

module type Intf = sig
  module type S = S
  module type Maker = Maker

  module Make : Maker
end
