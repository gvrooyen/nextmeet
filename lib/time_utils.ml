let get_current_time () =
  Ptime_clock.now ()

let time_window_minutes = 10

let format_rfc3339 time =
  Ptime.to_rfc3339 time

let parse_rfc3339 time_str =
  match Ptime.of_rfc3339 time_str with
  | Ok (time, _, _) -> Some time
  | Error _ -> None

let add_minutes time minutes =
  let seconds = minutes * 60 in
  match Ptime.add_span time (Ptime.Span.of_int_s seconds) with
  | Some new_time -> new_time
  | None -> time (* fallback to original time if addition fails *)

let subtract_minutes time minutes =
  let seconds = minutes * 60 in
  match Ptime.sub_span time (Ptime.Span.of_int_s seconds) with
  | Some new_time -> new_time
  | None -> time (* fallback to original time if subtraction fails *)

let get_time_window () =
  let current_time = get_current_time () in
  let time_min = subtract_minutes current_time time_window_minutes in
  let time_max = add_minutes current_time time_window_minutes in
  (time_min, time_max)

let get_time_window_rfc3339 () =
  let (time_min, time_max) = get_time_window () in
  (format_rfc3339 time_min, format_rfc3339 time_max)

let is_time_in_window event_start_time =
  let (time_min, time_max) = get_time_window () in
  match parse_rfc3339 event_start_time with
  | Some event_time ->
    Ptime.is_later event_time ~than:time_min && 
    Ptime.is_earlier event_time ~than:time_max
  | None -> false

let time_until_event event_start_time =
  let current_time = get_current_time () in
  match parse_rfc3339 event_start_time with
  | Some event_time ->
    (match Ptime.diff event_time current_time with
    | span -> 
      let seconds = Ptime.Span.to_float_s span in
      Some (seconds /. 60.0) (* return minutes *)
    )
  | None -> None

let debug_time_info () =
  let current_time = get_current_time () in
  let (time_min, time_max) = get_time_window () in
  Printf.printf "Current time: %s\n" (format_rfc3339 current_time);
  Printf.printf "Window start: %s\n" (format_rfc3339 time_min);
  Printf.printf "Window end: %s\n" (format_rfc3339 time_max);
  flush stdout
