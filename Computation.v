(** The definition of computations, used to represent interactive programs. *)
Require Import ListString.All.
Require Import Model.

Local Open Scope type.

Module Command.
  Inductive t :=
  | FileRead
  | Log
  | ModelGet.

  Definition request (command : t) : Type :=
    match command with
    | FileRead => LString.t
    | Log => LString.t
    | ModelGet => unit
    end.

  Definition answer (command : t) : Type :=
    match command with
    | FileRead => option LString.t
    | Log => unit
    | ModelGet => Users.t
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
