open Lwt.Syntax
open Nextmeet

(* Production version - silent operation as per requirements *)
let nextmeet () =
  let* result = Auth.get_valid_tokens ~silent:true () in
  match result with
  | Ok tokens ->
    (* Fetch events from Google Calendar *)
    let* events_result = Calendar.get_events_in_window tokens.access_token in
    (match events_result with
    | Ok events ->
      (* Look for Google Meet URLs *)
      (match Meet_parser.get_first_meet_url events with
      | Some meet_url ->
        (* Print only the URL and exit with code 0 *)
        Printf.printf "%s\n" meet_url;
        Lwt.return 0
      | None ->
        (* Silent operation - no output, exit with code 1 *)
        Lwt.return 1)
    | Error _msg ->
      (* Silent failure - no output, exit with code 1 *)
      Lwt.return 1)
  | Error msg ->
    (* Authentication errors should be shown to help user setup *)
    Printf.eprintf "Authentication failed: %s\n" msg;
    Printf.eprintf "Please ensure your Google OAuth2 credentials are set up correctly.\n";
    Printf.eprintf "Save credentials to: %s\n" (Config.credentials_file ());
    Lwt.return 1

let () =
  (* Initialize random seed for OAuth2 state generation *)
  Random.self_init ();
  
  (* Handle exceptions gracefully *)
  try
    let exit_code = Lwt_main.run (nextmeet ()) in
    exit exit_code
  with
  | exn ->
    (* Silent failure on unexpected exceptions *)
    Printf.eprintf "Unexpected error: %s\n" (Printexc.to_string exn);
    exit 1
