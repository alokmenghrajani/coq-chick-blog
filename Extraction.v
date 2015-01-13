Require Import ExtrOcamlBasic.
Require Import ExtrOcamlBigIntConv.
Require Import ExtrOcamlString.
Require Import ErrorHandlers.All.
Require Import FunctionNinjas.All.
Require Import ListString.All.
Require Import Computation.
Require Http.
Require Import Model.
Require View.

Module OCaml.
  Module String.
    Parameter t : Type.
    Extract Constant t => "string".

    Parameter of_lstring : LString.t -> t.
    Extract Constant of_lstring => "OCaml.String.of_lstring".

    Parameter to_lstring : t -> LString.t.
    Extract Constant to_lstring => "OCaml.String.to_lstring".
  End String.
End OCaml.

Module Lwt.
  Parameter t : Type -> Type.
  Extract Constant t "'a" => "'a Lwt.t".

  Parameter ret : forall {A : Type}, A -> t A.
  Extract Constant ret => "Lwt.return".

  Parameter bind : forall {A B : Type}, t A -> (A -> t B) -> t B.
  Extract Constant bind => "Lwt.bind".

  Parameter run : forall {A : Type}, t A -> A.
  Extract Constant run => "Lwt_main.run".

  Parameter printl : OCaml.String.t -> t unit.
  Extract Constant printl => "Lwt_io.printl".

  Parameter read_file : OCaml.String.t -> t (option OCaml.String.t).
  Extract Constant read_file => "fun file_name ->
    Lwt.catch(fun _ ->
      Lwt.bind (Lwt_io.open_file Lwt_io.Input file_name) (fun channel ->
      Lwt.bind (Lwt_io.read channel) (fun content ->
      Lwt.return @@ Some content)))
      (fun _ -> Lwt.return None)".
End Lwt.

Module Model.
  Parameter users_get : unit -> list (OCaml.String.t * (OCaml.String.t * OCaml.String.t)).
  Extract Constant users_get => "Model.users_get".
End Model.

Fixpoint eval {A : Type} (x : C.t A) : Lwt.t A :=
  match x with
  | C.Ret x => Lwt.ret x
  | C.Let (Command.FileRead file_name) handler =>
    let file_name := OCaml.String.of_lstring file_name in
    Lwt.bind (Lwt.read_file file_name) (fun content =>
    eval @@ handler @@ option_map OCaml.String.to_lstring content)
  | C.Let (Command.ListFiles directory) handler =>
    eval @@ handler None
  | C.Let (Command.Log message) handler =>
    let message := OCaml.String.of_lstring message in
    Lwt.bind (Lwt.printl message) (fun _ =>
    eval @@ handler tt)
  | C.Let Command.ModelGet handler =>
    let users := Model.users_get tt |> List.map (fun user =>
      match user with
      | (login, (password, email)) =>
        (OCaml.String.to_lstring login,
          User.New (OCaml.String.to_lstring password) (OCaml.String.to_lstring email))
      end) in
    eval @@ handler users
  end.

Parameter main_loop :
  (list OCaml.String.t -> list (OCaml.String.t * list OCaml.String.t) ->
    Lwt.t (OCaml.String.t * OCaml.String.t)) ->
  unit.
Extract Constant main_loop => "fun handler ->
  Lwt_main.run (Http.start_server handler 8008)".

Definition main (handler : Http.Request.t -> C.t Http.Answer.t) : unit :=
  main_loop (fun path args =>
    let path := List.map OCaml.String.to_lstring path in
    let args := args |> List.map (fun (arg : _ * _) =>
      let (name, values) := arg in
      (OCaml.String.to_lstring name, List.map OCaml.String.to_lstring values)) in
    let request := Http.Request.Get path args in
    Lwt.bind (eval @@ handler request) (fun answer =>
    let mime_type := OCaml.String.of_lstring @@ View.mime_type answer in
    let content := OCaml.String.of_lstring @@ View.content answer in
    Lwt.ret (mime_type, content))).
