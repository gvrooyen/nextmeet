open Alcotest
open Nextmeet.Config

let test_credentials_serialization () =
  (* Test default credentials *)
  let default_creds = default_credentials () in
  check string "default client_id" "" default_creds.client_id;
  check string "default redirect_uri" "http://localhost:8080" default_creds.redirect_uri;
  
  (* Test scope constant *)
  check string "google scope" "https://www.googleapis.com/auth/calendar.readonly" google_auth_scope

let test_token_validation () =
  let current_time = Unix.time () in
  
  (* Valid token (expires in 1 hour) *)
  let valid_tokens = {
    access_token = "valid_token";
    refresh_token = Some "refresh_token";
    expires_at = current_time +. 3600.0; (* 1 hour from now *)
  } in
  check bool "valid token" true (is_token_valid valid_tokens);
  
  (* Expired token *)
  let expired_tokens = {
    access_token = "expired_token";
    refresh_token = Some "refresh_token";
    expires_at = current_time -. 3600.0; (* 1 hour ago *)
  } in
  check bool "expired token" false (is_token_valid expired_tokens);
  
  (* Token expiring soon (within 5 minute buffer) *)
  let expiring_soon_tokens = {
    access_token = "expiring_token";
    refresh_token = Some "refresh_token";
    expires_at = current_time +. 60.0; (* 1 minute from now *)
  } in
  check bool "token expiring soon" false (is_token_valid expiring_soon_tokens)

let test_config_paths () =
  let home = Sys.getenv "HOME" in
  let expected_config_dir = Filename.concat home ".config/nextmeet" in
  let expected_credentials = Filename.concat expected_config_dir "credentials.json" in
  let expected_tokens = Filename.concat expected_config_dir "tokens.json" in
  
  check string "config directory" expected_config_dir (config_dir ());
  check string "credentials file" expected_credentials (credentials_file ());
  check string "tokens file" expected_tokens (tokens_file ())

let config_tests = [
  "credentials serialization", `Quick, test_credentials_serialization;
  "token validation", `Quick, test_token_validation;
  "config paths", `Quick, test_config_paths;
]
