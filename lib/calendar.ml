open Lwt.Syntax

type calendar_event = {
  id : string;
  summary : string option;
  description : string option;
  start_time : string option;
  end_time : string option;
  location : string option;
  hangout_link : string option;
  conference_data : Yojson.Safe.t option;
}

let google_calendar_api_base = "https://www.googleapis.com/calendar/v3"

let build_events_url time_min time_max =
  let base_url = google_calendar_api_base ^ "/calendars/primary/events" in
  let params = [
    ("timeMin", [time_min]);
    ("timeMax", [time_max]);
    ("singleEvents", ["true"]);
    ("orderBy", ["startTime"]);
    ("maxResults", ["10"]); (* Reduced from 50 - we only need a few events *)
    ("fields", ["items(id,summary,description,location,start,end,hangoutLink,conferenceData)"]); (* Include Google Meet fields *)
  ] in
  let uri = Uri.of_string base_url in
  Uri.with_query uri params

let make_authenticated_request url access_token =
  let headers = Cohttp.Header.init_with "Authorization" ("Bearer " ^ access_token) in
  try
    let* response, body = Cohttp_lwt_unix.Client.get ~headers url in
    let* body_string = Cohttp_lwt.Body.to_string body in
    
    match Cohttp.Response.status response with
    | `OK -> Lwt.return (Ok body_string)
    | `Unauthorized -> Lwt.return (Error "Authentication failed - invalid or expired token")
    | `Forbidden -> Lwt.return (Error "Access denied - insufficient permissions")
    | `Not_found -> Lwt.return (Error "Calendar not found")
    | `Too_many_requests -> Lwt.return (Error "Rate limit exceeded")
    | status ->
      let error_msg = Printf.sprintf "API request failed: %s" 
        (Cohttp.Code.string_of_status status) in
      Lwt.return (Error error_msg)
  with
  | Unix.Unix_error (Unix.ECONNREFUSED, _, _) -> Lwt.return (Error "Network connection refused")
  | Unix.Unix_error (Unix.EHOSTUNREACH, _, _) -> Lwt.return (Error "Host unreachable")
  | Unix.Unix_error (Unix.ETIMEDOUT, _, _) -> Lwt.return (Error "Network timeout")
  | exn -> Lwt.return (Error ("Network error: " ^ Printexc.to_string exn))

let parse_datetime json_value =
  let open Yojson.Safe.Util in
  try
    (* Try dateTime first (for specific times) *)
    match json_value |> member "dateTime" with
    | `String datetime -> Some datetime
    | _ ->
      (* Fall back to date (for all-day events) *)
      (match json_value |> member "date" with
      | `String date -> Some (date ^ "T00:00:00Z")
      | _ -> None)
  with
  | _ -> None

let parse_event_json json =
  let open Yojson.Safe.Util in
  try
    let id = json |> member "id" |> to_string in
    let summary = json |> member "summary" |> to_string_option in
    let description = json |> member "description" |> to_string_option in
    let start_time = json |> member "start" |> parse_datetime in
    let end_time = json |> member "end" |> parse_datetime in
    let location = json |> member "location" |> to_string_option in
    let hangout_link = json |> member "hangoutLink" |> to_string_option in
    let conference_data = 
      match json |> member "conferenceData" with
      | `Null -> None
      | data -> Some data
    in
    
    Some {
      id;
      summary;
      description;
      start_time;
      end_time;
      location;
      hangout_link;
      conference_data;
    }
  with
  | _ -> None

let parse_events_response body_string =
  try
    let json = Yojson.Safe.from_string body_string in
    let open Yojson.Safe.Util in
    let items = json |> member "items" |> to_list in
    let events = List.filter_map parse_event_json items in
    Ok events
  with
  | Yojson.Json_error msg -> Error ("JSON parse error: " ^ msg)
  | exn -> Error ("Parse error: " ^ Printexc.to_string exn)

let filter_events_in_window events =
  List.filter (fun event ->
    match event.start_time with
    | Some start_time -> 
      (* Validate the time format and check if it's in window *)
      (match Time_utils.parse_rfc3339 start_time with
      | Some _ -> Time_utils.is_time_in_window start_time
      | None -> false)
    | None -> false
  ) events

let get_events_in_window access_token =
  let (time_min, time_max) = Time_utils.get_time_window_rfc3339 () in
  let url = build_events_url time_min time_max in
  
  (* Silent operation - no debug output *)
  
  let* result = make_authenticated_request url access_token in
  match result with
  | Ok body_string ->
    (match parse_events_response body_string with
    | Ok events ->
      let filtered_events = filter_events_in_window events in
      Lwt.return (Ok filtered_events)
    | Error msg ->
      Lwt.return (Error msg))
  | Error msg ->
    Lwt.return (Error msg)

let print_event_debug event =
  Printf.printf "Event: %s\n" event.id;
  Printf.printf "  Summary: %s\n" (Option.value event.summary ~default:"(no title)");
  Printf.printf "  Start: %s\n" (Option.value event.start_time ~default:"(no start time)");
  Printf.printf "  Description: %s\n" (Option.value event.description ~default:"(no description)");
  Printf.printf "  Location: %s\n" (Option.value event.location ~default:"(no location)");
  Printf.printf "  Hangout Link: %s\n" (Option.value event.hangout_link ~default:"(no hangout link)");
  Printf.printf "  Conference Data: %s\n" (match event.conference_data with
    | Some data -> Yojson.Safe.pretty_to_string data
    | None -> "(no conference data)");
  (match event.start_time with
  | Some start_time ->
    (match Time_utils.time_until_event start_time with
    | Some minutes ->
      Printf.printf "  Time until start: %.1f minutes\n" minutes
    | None ->
      Printf.printf "  Time until start: unknown\n")
  | None -> ());
  Printf.printf "\n";
  flush stdout

let debug_events events =
  Printf.printf "\n=== Event Debug Info ===\n";
  List.iter print_event_debug events;
  Printf.printf "=== End Debug Info ===\n\n";
  flush stdout
