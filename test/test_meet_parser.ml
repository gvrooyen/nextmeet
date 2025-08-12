open Alcotest
open Nextmeet

let test_extract_meet_url_from_string () =
  let test_cases = [
    ("Join the meeting at https://meet.google.com/abc-defg-hij", 
     Some "https://meet.google.com/abc-defg-hij");
    ("Meeting link: https://meet.google.com/xyz-uvwx-rst?authuser=0", 
     Some "https://meet.google.com/xyz-uvwx-rst");
    ("Google Meet: https://meet.google.com/abc-def-ghi", 
     Some "https://meet.google.com/abc-def-ghi");
    ("No meeting link in this text", None);
    ("", None);
  ] in
  
  List.iteri (fun i (text, expected) ->
    let result = Meet_parser.extract_meet_url_from_string text in
    let test_name = Printf.sprintf "extract URL test %d" (i + 1) in
    check (option string) test_name expected result
  ) test_cases

let test_extract_from_hangout_link () =
  let event = Calendar.{
    id = "test1";
    summary = Some "Test Meeting";
    description = None;
    start_time = Some "2024-01-01T12:00:00Z";
    end_time = Some "2024-01-01T13:00:00Z";
    location = None;
    hangout_link = Some "https://meet.google.com/test-link-abc";
    conference_data = None;
  } in
  
  let result = Meet_parser.extract_meet_url_from_event event in
  check (option string) "hangout link extraction" 
    (Some "https://meet.google.com/test-link-abc") result

let test_extract_from_conference_data () =
  let conference_json = `Assoc [
    ("entryPoints", `List [
      `Assoc [
        ("entryPointType", `String "video");
        ("uri", `String "https://meet.google.com/conf-data-test");
        ("label", `String "meet.google.com/conf-data-test");
      ];
      `Assoc [
        ("entryPointType", `String "phone");
        ("uri", `String "tel:+1234567890");
      ];
    ]);
  ] in
  
  let result = Meet_parser.extract_meet_url_from_conference_data conference_json in
  check (option string) "conference data extraction" 
    (Some "https://meet.google.com/conf-data-test") result

let test_extract_from_conference_data_no_video () =
  let conference_json = `Assoc [
    ("entryPoints", `List [
      `Assoc [
        ("entryPointType", `String "phone");
        ("uri", `String "tel:+1234567890");
      ];
    ]);
  ] in
  
  let result = Meet_parser.extract_meet_url_from_conference_data conference_json in
  check (option string) "conference data no video" None result

let test_extract_from_event_with_conference_data () =
  let conference_json = `Assoc [
    ("entryPoints", `List [
      `Assoc [
        ("entryPointType", `String "video");
        ("uri", `String "https://meet.google.com/event-conf-test");
      ];
    ]);
  ] in
  
  let event = Calendar.{
    id = "test2";
    summary = Some "Conference Test";
    description = Some "Regular meeting";
    start_time = Some "2024-01-01T14:00:00Z";
    end_time = Some "2024-01-01T15:00:00Z";
    location = None;
    hangout_link = None;
    conference_data = Some conference_json;
  } in
  
  let result = Meet_parser.extract_meet_url_from_event event in
  check (option string) "event conference data extraction" 
    (Some "https://meet.google.com/event-conf-test") result

let test_extract_from_description_fallback () =
  let event = Calendar.{
    id = "test3";
    summary = Some "Fallback Test";
    description = Some "Join us at https://meet.google.com/fallback-test for the meeting";
    start_time = Some "2024-01-01T16:00:00Z";
    end_time = Some "2024-01-01T17:00:00Z";
    location = None;
    hangout_link = None;
    conference_data = None;
  } in
  
  let result = Meet_parser.extract_meet_url_from_event event in
  check (option string) "description fallback extraction" 
    (Some "https://meet.google.com/fallback-test") result

let test_no_meet_url_found () =
  let event = Calendar.{
    id = "test4";
    summary = Some "No Meet URL";
    description = Some "This is just a regular meeting with no video link";
    start_time = Some "2024-01-01T18:00:00Z";
    end_time = Some "2024-01-01T19:00:00Z";
    location = Some "Conference Room A";
    hangout_link = None;
    conference_data = None;
  } in
  
  let result = Meet_parser.extract_meet_url_from_event event in
  check (option string) "no URL found" None result

let test_get_first_meet_url () =
  let events = [
    Calendar.{
      id = "no_meet";
      summary = Some "No Meet";
      description = Some "Regular meeting";
      start_time = Some "2024-01-01T10:00:00Z";
      end_time = Some "2024-01-01T11:00:00Z";
      location = None;
      hangout_link = None;
      conference_data = None;
    };
    Calendar.{
      id = "with_meet";
      summary = Some "With Meet";
      description = Some "Join at https://meet.google.com/first-url-test";
      start_time = Some "2024-01-01T12:00:00Z";
      end_time = Some "2024-01-01T13:00:00Z";
      location = None;
      hangout_link = None;
      conference_data = None;
    };
    Calendar.{
      id = "second_meet";
      summary = Some "Second Meet";
      description = Some "Another meeting https://meet.google.com/second-url-test";
      start_time = Some "2024-01-01T14:00:00Z";
      end_time = Some "2024-01-01T15:00:00Z";
      location = None;
      hangout_link = None;
      conference_data = None;
    };
  ] in
  
  let result = Meet_parser.get_first_meet_url events in
  check (option string) "first URL from list" 
    (Some "https://meet.google.com/first-url-test") result

let meet_parser_tests = [
  "extract URL from string", `Quick, test_extract_meet_url_from_string;
  "extract from hangout link", `Quick, test_extract_from_hangout_link;
  "extract from conference data", `Quick, test_extract_from_conference_data;
  "extract from conference data no video", `Quick, test_extract_from_conference_data_no_video;
  "extract from event with conference data", `Quick, test_extract_from_event_with_conference_data;
  "extract from description fallback", `Quick, test_extract_from_description_fallback;
  "no meet URL found", `Quick, test_no_meet_url_found;
  "get first meet URL", `Quick, test_get_first_meet_url;
]
