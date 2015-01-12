(** The definition of computations, used to represent interactive programs. *)
Require Import ListString.All.

Local Open Scope type.

Module Command.
  Module Database.
    Inductive t :=
    | IsSignedUp.

    Definition request (command : t) : Type :=
      match command with
      | IsSignedUp => LString.t * LString.t
      end.

    Definition answer (command : t) : Type :=
      match command with
      | IsSignedUp => bool
      end.
  End Database.

  Inductive t :=
  | Log
  | Database (command : Database.t).

  Definition request (command : t) : Type :=
    match command with
    | Log => LString.t
    | Database command => Database.request command
    end.

  Definition answer (command : t) : Type :=
    match command with
    | Log => unit
    | Database command => Database.answer command
    end.
End Command.

Module C.
  Inductive t (A : Type) : Type :=
  | Ret : forall (x : A), t A
  | Let : forall (command : Command.t), Command.request command ->
    (Command.answer command -> t A) -> t A.
  Arguments Ret {A} _.
  Arguments Let {A} _ _ _.

  Module Notations.
    Notation "'let!' answer ':=' command '@' request 'in' X" :=
      (Let command request (fun answer => X))
      (at level 200, answer ident, request at level 100, command at level 100, X at level 200).

    Notation "'do!' command '@' request 'in' X" :=
      (Let command request (fun _ => X))
      (at level 200, request at level 100, command at level 100, X at level 200).
  End Notations.
End C.
