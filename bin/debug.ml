open Lwt.Syntax
open Nextmeet

(* Debug version to test functionality *)
let test_with_debug () =
  Printf.printf "=== DEBUG MODE: Testing nextmeet functionality ===\n";
  
  let* result = Auth.get_valid_tokens ~silent:false () in
  match result with
  | Ok tokens ->
    Printf.printf "✅ Authentication successful!\n";
    
    (* Show current time window *)
    Time_utils.debug_time_info ();
    
    (* Fetch events from Google Calendar *)
    let* events_result = Calendar.get_events_in_window tokens.access_token in
    (match events_result with
    | Ok events ->
      Printf.printf "✅ Successfully fetched %d events\n" (List.length events);
      
      (* Debug: show all events *)
      Calendar.debug_events events;
      
      (* Look for Google Meet URLs *)
      let meet_urls = Meet_parser.find_meet_urls_in_events events in
      Printf.printf "Found %d events with Google Meet URLs:\n" (List.length meet_urls);
      List.iter (fun (event, url) ->
        Printf.printf "  - %s: %s\n" 
          (Option.value event.Calendar.summary ~default:"(no title)")
          url
      ) meet_urls;
      
      (match Meet_parser.get_first_meet_url events with
      | Some meet_url ->
        Printf.printf "\n🎯 RESULT: %s\n" meet_url;
        Printf.printf "✅ EXIT CODE: 0 (meeting found)\n";
        Lwt.return 0
      | None ->
        Printf.printf "\n❌ RESULT: No Google Meet links found\n";
        Printf.printf "✅ EXIT CODE: 1 (no meeting found)\n";
        Lwt.return 1)
    | Error msg ->
      Printf.eprintf "❌ Failed to fetch calendar events: %s\n" msg;
      Printf.printf "✅ EXIT CODE: 1 (error)\n";
      Lwt.return 1)
  | Error msg ->
    Printf.eprintf "❌ Authentication failed: %s\n" msg;
    Printf.printf "✅ EXIT CODE: 1 (auth error)\n";
    Lwt.return 1

let () =
  Random.self_init ();
  let exit_code = Lwt_main.run (test_with_debug ()) in
  exit exit_code
