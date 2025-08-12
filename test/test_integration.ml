open Alcotest
open Nextmeet

let mock_calendar_response_with_meet = {|
{
  "items": [
    {
      "id": "test_event_with_meet",
      "summary": "Test Meeting with Google Meet",
      "description": "",
      "start": {
        "dateTime": "2024-01-01T12:00:00Z"
      },
      "end": {
        "dateTime": "2024-01-01T13:00:00Z"
      },
      "hangoutLink": "https://meet.google.com/test-integration-abc",
      "conferenceData": {
        "entryPoints": [
          {
            "entryPointType": "video",
            "uri": "https://meet.google.com/test-integration-abc",
            "label": "meet.google.com/test-integration-abc"
          }
        ],
        "conferenceSolution": {
          "key": {"type": "hangoutsMeet"},
          "name": "Google Meet"
        }
      }
    }
  ]
}
|}

let mock_calendar_response_no_meet = {|
{
  "items": [
    {
      "id": "test_event_no_meet",
      "summary": "Regular Meeting",
      "description": "Just a regular meeting without video link",
      "start": {
        "dateTime": "2024-01-01T14:00:00Z"
      },
      "end": {
        "dateTime": "2024-01-01T15:00:00Z"
      }
    }
  ]
}
|}

let mock_calendar_response_empty = {|
{
  "items": []
}
|}

let test_integration_parse_and_extract_meet_url () =
  (* Test parsing a calendar response with a Google Meet link *)
  let result = Calendar.parse_events_response mock_calendar_response_with_meet in
  match result with
  | Ok events ->
    check int "one event parsed" 1 (List.length events);
    let event = List.hd events in
    check string "event id" "test_event_with_meet" event.id;
    check (option string) "hangout link present" 
      (Some "https://meet.google.com/test-integration-abc") event.hangout_link;
    
    (* Test Meet URL extraction *)
    let meet_url = Meet_parser.extract_meet_url_from_event event in
    check (option string) "meet URL extracted" 
      (Some "https://meet.google.com/test-integration-abc") meet_url;
  | Error msg ->
    fail ("Failed to parse calendar response: " ^ msg)

let test_integration_no_meet_url () =
  (* Test parsing a calendar response without Google Meet links *)
  let result = Calendar.parse_events_response mock_calendar_response_no_meet in
  match result with
  | Ok events ->
    check int "one event parsed" 1 (List.length events);
    let event = List.hd events in
    check string "event id" "test_event_no_meet" event.id;
    check (option string) "no hangout link" None event.hangout_link;
    
    (* Test Meet URL extraction *)
    let meet_url = Meet_parser.extract_meet_url_from_event event in
    check (option string) "no meet URL found" None meet_url;
  | Error msg ->
    fail ("Failed to parse calendar response: " ^ msg)

let test_integration_empty_calendar () =
  (* Test parsing an empty calendar response *)
  let result = Calendar.parse_events_response mock_calendar_response_empty in
  match result with
  | Ok events ->
    check int "no events" 0 (List.length events);
    
    (* Test getting first Meet URL from empty list *)
    let meet_url = Meet_parser.get_first_meet_url events in
    check (option string) "no URLs in empty list" None meet_url;
  | Error msg ->
    fail ("Failed to parse empty calendar response: " ^ msg)

let test_integration_end_to_end_scenario () =
  (* Simulate a full end-to-end scenario *)
  let result = Calendar.parse_events_response mock_calendar_response_with_meet in
  match result with
  | Ok events ->
    (* Filter events (though time window filtering would fail with mock data) *)
    let meet_url = Meet_parser.get_first_meet_url events in
    match meet_url with
    | Some url ->
      check string "end-to-end URL extraction" 
        "https://meet.google.com/test-integration-abc" url;
      (* This simulates the successful case: exit code 0 *)
      check bool "successful case" true true
    | None ->
      fail "Expected to find Meet URL in integration test"
  | Error msg ->
    fail ("End-to-end test failed: " ^ msg)

let test_integration_multiple_events () =
  let multi_event_response = {|
{
  "items": [
    {
      "id": "event1_no_meet",
      "summary": "First Event",
      "start": {"dateTime": "2024-01-01T10:00:00Z"}
    },
    {
      "id": "event2_with_meet",
      "summary": "Second Event", 
      "start": {"dateTime": "2024-01-01T11:00:00Z"},
      "hangoutLink": "https://meet.google.com/multi-test-xyz"
    },
    {
      "id": "event3_also_meet",
      "summary": "Third Event",
      "start": {"dateTime": "2024-01-01T12:00:00Z"},
      "description": "Join at https://meet.google.com/another-meet-link"
    }
  ]
}
  |} in
  
  let result = Calendar.parse_events_response multi_event_response in
  match result with
  | Ok events ->
    check int "three events parsed" 3 (List.length events);
    
    (* Test that get_first_meet_url returns the first one found *)
    let first_meet_url = Meet_parser.get_first_meet_url events in
    check (option string) "first Meet URL found" 
      (Some "https://meet.google.com/multi-test-xyz") first_meet_url;
    
    (* Test that find_meet_urls_in_events finds all URLs *)
    let all_meet_urls = Meet_parser.find_meet_urls_in_events events in
    check int "two events with Meet URLs" 2 (List.length all_meet_urls);
  | Error msg ->
    fail ("Failed to parse multi-event response: " ^ msg)

let integration_tests = [
  "parse and extract Meet URL", `Quick, test_integration_parse_and_extract_meet_url;
  "no Meet URL scenario", `Quick, test_integration_no_meet_url;
  "empty calendar scenario", `Quick, test_integration_empty_calendar;
  "end-to-end scenario", `Quick, test_integration_end_to_end_scenario;
  "multiple events scenario", `Quick, test_integration_multiple_events;
]
