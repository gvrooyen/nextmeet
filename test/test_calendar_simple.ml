open Alcotest
open Nextmeet

let test_parse_datetime () =
  (* Test with dateTime field *)
  let datetime_json = `Assoc [
    ("dateTime", `String "2024-01-01T12:00:00Z");
    ("timeZone", `String "UTC");
  ] in
  let result1 = Calendar.parse_datetime datetime_json in
  check (option string) "parse dateTime" (Some "2024-01-01T12:00:00Z") result1

let test_build_events_url () =
  let time_min = "2024-01-01T10:00:00Z" in
  let time_max = "2024-01-01T12:00:00Z" in
  let url = Calendar.build_events_url time_min time_max in
  let url_string = Uri.to_string url in
  
  let contains_substring str sub = 
    try ignore (Str.search_forward (Str.regexp_string sub) str 0); true
    with Not_found -> false in
  check bool "contains base URL" true 
    (contains_substring url_string "googleapis.com/calendar/v3")

let calendar_tests = [
  "parse datetime", `Quick, test_parse_datetime;
  "build events URL", `Quick, test_build_events_url;
]
