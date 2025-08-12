open Alcotest
open Nextmeet.Time_utils

let test_rfc3339_formatting () =
  let test_time = Ptime.of_date_time ((2024, 1, 1), ((12, 0, 0), 0)) in
  match test_time with
  | Some time ->
    let formatted = format_rfc3339 time in
    check string "RFC3339 format" "2024-01-01T12:00:00-00:00" formatted
  | None ->
    fail "Failed to create test time"

let test_rfc3339_parsing () =
  let test_string = "2024-01-01T12:00:00Z" in
  let parsed = parse_rfc3339 test_string in
  check bool "RFC3339 parsing succeeds" true (Option.is_some parsed);
  
  let invalid_string = "invalid-date" in
  let parsed_invalid = parse_rfc3339 invalid_string in
  check bool "Invalid RFC3339 parsing fails" true (Option.is_none parsed_invalid)

let test_time_window_calculation () =
  let (time_min, time_max) = get_time_window () in
  let current = get_current_time () in
  
  (* Check that time_min is before current time *)
  check bool "time_min before current" true (Ptime.is_earlier time_min ~than:current);
  
  (* Check that time_max is after current time *)
  check bool "time_max after current" true (Ptime.is_later time_max ~than:current);
  
  (* Check that the window is approximately 20 minutes (±10) *)
  let diff = Ptime.diff time_max time_min in
  let diff_minutes = Ptime.Span.to_float_s diff /. 60.0 in
  check (float 0.1) "window size ~20 minutes" 20.0 diff_minutes

let test_add_subtract_minutes () =
  let base_time = Ptime.of_date_time ((2024, 1, 1), ((12, 0, 0), 0)) in
  match base_time with
  | Some time ->
    let plus_10 = add_minutes time 10 in
    let minus_10 = subtract_minutes time 10 in
    
    (* Check that adding then subtracting returns to original *)
    let back_to_original = subtract_minutes plus_10 10 in
    check bool "add/subtract symmetry" true (Ptime.equal time back_to_original);
    
    (* Check that the difference is correct *)
    let diff = Ptime.diff plus_10 minus_10 in
    let diff_minutes = Ptime.Span.to_float_s diff /. 60.0 in
    check (float 0.1) "20 minute difference" 20.0 diff_minutes
  | None ->
    fail "Failed to create base time"

let test_is_time_in_window () =
  let current = get_current_time () in
  let current_str = format_rfc3339 current in
  
  (* Current time should be in window *)
  check bool "current time in window" true (is_time_in_window current_str);
  
  (* Time 5 minutes ago should be in window *)
  let five_min_ago = subtract_minutes current 5 in
  let five_min_ago_str = format_rfc3339 five_min_ago in
  check bool "5 min ago in window" true (is_time_in_window five_min_ago_str);
  
  (* Time 15 minutes ago should be outside window *)
  let fifteen_min_ago = subtract_minutes current 15 in
  let fifteen_min_ago_str = format_rfc3339 fifteen_min_ago in
  check bool "15 min ago outside window" false (is_time_in_window fifteen_min_ago_str)

let test_time_until_event () =
  let current = get_current_time () in
  let future_event = add_minutes current 5 in
  let future_event_str = format_rfc3339 future_event in
  
  match time_until_event future_event_str with
  | Some minutes ->
    check (float 1.0) "time until event ~5 minutes" 5.0 minutes
  | None ->
    fail "Failed to calculate time until event"

let time_utils_tests = [
  "RFC3339 formatting", `Quick, test_rfc3339_formatting;
  "RFC3339 parsing", `Quick, test_rfc3339_parsing;
  "time window calculation", `Quick, test_time_window_calculation;
  "add/subtract minutes", `Quick, test_add_subtract_minutes;
  "is time in window", `Quick, test_is_time_in_window;
  "time until event", `Quick, test_time_until_event;
]
