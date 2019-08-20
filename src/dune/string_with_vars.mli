(** String with variables of the form ${...} or $(...)

    Variables cannot contain "${", "$(", ")" or "}". For instance in "$(cat
    ${x})", only "${x}" will be considered a variable, the rest is text. *)
open! Stdune

open Import

(** A sequence of text and variables. *)
type t

val compare_no_loc : t -> t -> Ordering.t

(** [loc t] returns the location of [t] — typically, in the jbuild file. *)
val loc : t -> Loc.t

val syntax_version : t -> Syntax.Version.t

val to_dyn : t Dyn.Encoder.t

include Dune_lang.Conv with type t := t

(** [t] generated by the OCaml code. The first argument should be [__POS__].
    [quoted] says whether the string is quoted ([false] by default). *)
val virt_var : ?quoted:bool -> string * int * int * int -> string -> t

val virt_text : string * int * int * int -> string -> t

val make_var : ?quoted:bool -> Loc.t -> ?payload:string -> string -> t

val make_text : ?quoted:bool -> Loc.t -> string -> t

val make : Dune_lang.Template.t -> t

val is_var : t -> name:string -> bool

val has_vars : t -> bool

(** If [t] contains no variable, returns the contents of [t]. *)
val text_only : t -> string option

module Mode : sig
  type _ t =
    | Single : Value.t t
    | Many : Value.t list t
end

module Var : sig
  type t

  val to_dyn : t -> Dyn.t

  val name : t -> string

  val loc : t -> Loc.t

  val full_name : t -> string

  val payload : t -> string option

  val with_name : t -> name:string -> t

  val is_macro : t -> bool

  (** Describe what this variable is *)
  val describe : t -> string
end

type yes_no_unknown =
  | Yes
  | No
  | Unknown of Var.t

module Partial : sig
  type nonrec 'a t =
    | Expanded of 'a
    | Unexpanded of t

  val to_dyn : ('a -> Dyn.t) -> 'a t -> Dyn.t

  val map : 'a t -> f:('a -> 'b) -> 'b t

  val is_suffix : string t -> suffix:string -> yes_no_unknown

  val is_prefix : string t -> prefix:string -> yes_no_unknown
end

type known_suffix =
  | Full of string
  | Partial of (Var.t * string)

type known_prefix =
  | Full of string
  | Partial of (string * Var.t)

val known_suffix : t -> known_suffix

val known_prefix : t -> known_prefix

val is_suffix : t -> suffix:string -> yes_no_unknown

val is_prefix : t -> prefix:string -> yes_no_unknown

val fold_vars : t -> init:'a -> f:(Var.t -> 'a -> 'a) -> 'a

type 'a expander = Var.t -> Syntax.Version.t -> 'a

val expand :
  t -> mode:'a Mode.t -> dir:Path.t -> f:Value.t list option expander -> 'a

val partial_expand :
     t
  -> mode:'a Mode.t
  -> dir:Path.t
  -> f:Value.t list option expander
  -> 'a Partial.t

val remove_locs : t -> t