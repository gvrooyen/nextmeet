open Alcotest

let () =
  run "nextmeet" [
    "Time Utils", Test_time_utils.time_utils_tests;
    "Meet Parser", Test_meet_parser.meet_parser_tests;
    "Config", Test_config.config_tests;
    "Calendar", Test_calendar_simple.calendar_tests;
  ]
