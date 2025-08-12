open Alcotest
open Nextmeet

let test_parse_datetime () =
  (* Test with dateTime field *)
  let datetime_json = `Assoc [
    ("dateTime", `String "2024-01-01T12:00:00Z");
    ("timeZone", `String "UTC");
  ] in
  let result1 = Calendar.parse_datetime datetime_json in
  check (option string) "parse dateTime" (Some "2024-01-01T12:00:00Z") result1;
  
  (* Test with date field (all-day event) *)
  let date_json = `Assoc [
    ("date", `String "2024-01-01");
  ] in
  let result2 = Calendar.parse_datetime date_json in
  check (option string) "parse date" (Some "2024-01-01T00:00:00Z") result2;
  
  (* Test with no valid fields *)
  let empty_json = `Assoc [] in
  let result3 = Calendar.parse_datetime empty_json in
  check (option string) "parse empty" None result3

let test_parse_event_json () =
  let event_json = `Assoc [
    ("id", `String "test_event_123");
    ("summary", `String "Test Meeting");
    ("description", `String "Test description");
    ("location", `String "Conference Room");
    ("start", `Assoc [("dateTime", `String "2024-01-01T12:00:00Z")]);
    ("end", `Assoc [("dateTime", `String "2024-01-01T13:00:00Z")]);
    ("hangoutLink", `String "https://meet.google.com/test-meeting");
    ("conferenceData", `Assoc [
      ("entryPoints", `List [
        `Assoc [
          ("entryPointType", `String "video");
          ("uri", `String "https://meet.google.com/test-meeting");
        ]
      ])
    ]);
  ] in
  
  let result = Calendar.parse_event_json event_json in
  match result with
  | Some event ->
    check string "event id" "test_event_123" event.id;
    check (option string) "event summary" (Some "Test Meeting") event.summary;
    check (option string) "event description" (Some "Test description") event.description;
    check (option string) "event location" (Some "Conference Room") event.location;
    check (option string) "event start" (Some "2024-01-01T12:00:00Z") event.start_time;
    check (option string) "event end" (Some "2024-01-01T13:00:00Z") event.end_time;
    check (option string) "hangout link" (Some "https://meet.google.com/test-meeting") event.hangout_link;
    check bool "conference data present" true (Option.is_some event.conference_data);
  | None ->
    fail "Failed to parse valid event JSON"

let test_parse_minimal_event () =
  let minimal_json = `Assoc [
    ("id", `String "minimal_event");
  ] in
  
  let result = Calendar.parse_event_json minimal_json in
  match result with
  | Some event ->
    check string "minimal event id" "minimal_event" event.id;
    check (option string) "minimal summary" None event.summary;
    check (option string) "minimal description" None event.description;
    check (option string) "minimal hangout link" None event.hangout_link;
  | None ->
    fail "Failed to parse minimal event JSON"

let test_parse_events_response () =
  let response_json = {|
    {
      "items": [
        {
          "id": "event1",
          "summary": "First Event",
          "start": {"dateTime": "2024-01-01T10:00:00Z"}
        },
        {
          "id": "event2",
          "summary": "Second Event", 
          "start": {"dateTime": "2024-01-01T11:00:00Z"}
        }
      ]
    }
  |} in
  
  let result = Calendar.parse_events_response response_json in
  match result with
  | Ok events ->
    check int "events count" 2 (List.length events);
    let first_event = List.hd events in
    check string "first event id" "event1" first_event.id;
  | Error msg ->
    fail ("Failed to parse events response: " ^ msg)

let test_build_events_url () =
  let time_min = "2024-01-01T10:00:00Z" in
  let time_max = "2024-01-01T12:00:00Z" in
  let url = Calendar.build_events_url time_min time_max in
  let url_string = Uri.to_string url in
  
  (* Check that URL contains expected components *)
  let contains_substring str sub = 
    try ignore (Str.search_forward (Str.regexp_string sub) str 0); true
    with Not_found -> false in
  check bool "contains base URL" true 
    (contains_substring url_string "googleapis.com/calendar/v3");
  check bool "contains timeMin" true 
    (contains_substring url_string "timeMin=2024-01-01T10%3A00%3A00Z");
  check bool "contains timeMax" true 
    (contains_substring url_string "timeMax=2024-01-01T12%3A00%3A00Z");
  check bool "contains singleEvents" true 
    (contains_substring url_string "singleEvents=true");

let test_filter_events_in_window () =
  let current_time = Ptime_clock.now () in
  let in_window_time = Time_utils.add_minutes current_time 5 in
  let out_of_window_time = Time_utils.add_minutes current_time 15 in
  
  let events = [
    Calendar.{
      id = "in_window";
      summary = Some "In Window";
      description = None;
      start_time = Some (Time_utils.format_rfc3339 in_window_time);
      end_time = None;
      location = None;
      hangout_link = None;
      conference_data = None;
    };
    Calendar.{
      id = "out_of_window";
      summary = Some "Out of Window";
      description = None;
      start_time = Some (Time_utils.format_rfc3339 out_of_window_time);
      end_time = None;
      location = None;
      hangout_link = None;
      conference_data = None;
    };
    Calendar.{
      id = "no_start_time";
      summary = Some "No Start Time";
      description = None;
      start_time = None;
      end_time = None;
      location = None;
      hangout_link = None;
      conference_data = None;
    };
  ] in
  
  let filtered = Calendar.filter_events_in_window events in
  check int "filtered events count" 1 (List.length filtered);
  let filtered_event = List.hd filtered in
  check string "filtered event id" "in_window" filtered_event.id

let calendar_tests = [
  "parse datetime", `Quick, test_parse_datetime;
  "parse event JSON", `Quick, test_parse_event_json;
  "parse minimal event", `Quick, test_parse_minimal_event;
  "parse events response", `Quick, test_parse_events_response;
  "build events URL", `Quick, test_build_events_url;
  "filter events in window", `Quick, test_filter_events_in_window;
]
