let google_meet_patterns = [
  (* Standard Google Meet URL pattern *)
  "https://meet\\.google\\.com/[a-z][a-z][a-z]-[a-z][a-z][a-z][a-z]-[a-z][a-z][a-z]";
  (* Alternative patterns with different separators *)
  "https://meet\\.google\\.com/[a-z][a-z][a-z]-[a-z][a-z][a-z][a-z]-[a-z][a-z][a-z][a-z]";
  "https://meet\\.google\\.com/[a-z][a-z][a-z]-[a-z][a-z][a-z]-[a-z][a-z][a-z]";
  (* Google Meet URLs with additional parameters - simplified pattern *)
  "https://meet\\.google\\.com/[a-z-]+[?][^[:space:]]*";
  (* Catch-all pattern for any Google Meet URL *)
  "https://meet\\.google\\.com/[a-z-]+";
]

let create_regex pattern =
  try
    Some (Str.regexp pattern)
  with
  | _ -> None

let compiled_patterns = 
  List.filter_map create_regex google_meet_patterns

let extract_meet_url_from_string text =
  let rec try_patterns patterns =
    match patterns with
    | [] -> None
    | regex :: remaining ->
      (try
        ignore (Str.search_forward regex text 0);
        Some (Str.matched_string text)
      with
      | Not_found -> try_patterns remaining)
  in
  try_patterns compiled_patterns

let extract_meet_url_from_conference_data conference_data =
  try
    let open Yojson.Safe.Util in
    let entry_points = conference_data |> member "entryPoints" |> to_list in
    let rec find_video_entry = function
      | [] -> None
      | entry :: rest ->
        (match entry |> member "entryPointType" |> to_string_option with
        | Some "video" ->
          (match entry |> member "uri" |> to_string_option with
          | Some uri -> Some uri
          | None -> find_video_entry rest)
        | _ -> find_video_entry rest)
    in
    find_video_entry entry_points
  with
  | _ -> None

let extract_meet_url_from_event event =
  let open Calendar in
  let check_field field_opt =
    match field_opt with
    | Some text -> extract_meet_url_from_string text
    | None -> None
  in
  
  (* Check hangoutLink first (direct Google Meet link) *)
  (match event.hangout_link with
  | Some url -> Some url
  | None ->
    (* Check conferenceData for structured Google Meet info *)
    (match event.conference_data with
    | Some data ->
      (match extract_meet_url_from_conference_data data with
      | Some url -> Some url
      | None ->
        (* Fallback to text-based search in description *)
        (match check_field event.description with
        | Some url -> Some url
        | None ->
          (* Check location field *)
          (match check_field event.location with
          | Some url -> Some url
          | None ->
            (* Check summary as last resort *)
            check_field event.summary)))
    | None ->
      (* Fallback to text-based search in description *)
      (match check_field event.description with
      | Some url -> Some url
      | None ->
        (* Check location field *)
        (match check_field event.location with
        | Some url -> Some url
        | None ->
          (* Check summary as last resort *)
          check_field event.summary))))

let find_meet_urls_in_events events =
  List.filter_map (fun event ->
    match extract_meet_url_from_event event with
    | Some url -> Some (event, url)
    | None -> None
  ) events

let get_first_meet_url events =
  (* Optimized: stop at first match instead of processing all events *)
  let rec find_first = function
    | [] -> None
    | event :: rest ->
      (match extract_meet_url_from_event event with
      | Some url -> Some url
      | None -> find_first rest)
  in
  find_first events

let debug_meet_extraction event =
  Printf.printf "=== Meet URL Extraction Debug ===\n";
  Printf.printf "Event: %s\n" event.Calendar.id;
  Printf.printf "Summary: %s\n" (Option.value event.summary ~default:"(none)");
  Printf.printf "Description: %s\n" (Option.value event.description ~default:"(none)");
  Printf.printf "Location: %s\n" (Option.value event.location ~default:"(none)");
  
  let url = extract_meet_url_from_event event in
  Printf.printf "Extracted Meet URL: %s\n" (Option.value url ~default:"(none found)");
  Printf.printf "=== End Debug ===\n\n";
  flush stdout;
  url

(* Test function for development *)
let test_patterns () =
  let test_texts = [
    "Join the meeting at https://meet.google.com/abc-defg-hij";
    "Meeting link: https://meet.google.com/xyz-uvwx-rst?authuser=0";
    "Google Meet: https://meet.google.com/abc-def-ghi";
    "No meeting link in this text";
  ] in
  
  Printf.printf "=== Testing Meet URL Patterns ===\n";
  List.iter (fun text ->
    Printf.printf "Text: %s\n" text;
    Printf.printf "Extracted: %s\n" 
      (Option.value (extract_meet_url_from_string text) ~default:"(none)");
    Printf.printf "\n";
  ) test_texts;
  flush stdout
