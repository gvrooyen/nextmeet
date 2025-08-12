type oauth_credentials = {
  client_id : string;
  client_secret : string;
  redirect_uri : string;
}

type oauth_tokens = {
  access_token : string;
  refresh_token : string option;
  expires_at : float; (* Unix timestamp *)
}

let config_dir () =
  let home = Sys.getenv "HOME" in
  Filename.concat home ".config/nextmeet"

let credentials_file () =
  Filename.concat (config_dir ()) "credentials.json"

let tokens_file () =
  Filename.concat (config_dir ()) "tokens.json"

let ensure_config_dir () =
  let dir = config_dir () in
  if not (Sys.file_exists dir) then
    Unix.mkdir dir 0o700

let write_file filename content =
  ensure_config_dir ();
  let oc = open_out filename in
  Fun.protect
    ~finally:(fun () -> close_out oc)
    (fun () -> output_string oc content)

let read_file filename =
  if Sys.file_exists filename then
    let ic = open_in filename in
    Fun.protect
      ~finally:(fun () -> close_in ic)
      (fun () -> 
        let content = really_input_string ic (in_channel_length ic) in
        Some content)
  else
    None

let save_credentials credentials =
  let json = `Assoc [
    ("client_id", `String credentials.client_id);
    ("client_secret", `String credentials.client_secret);
    ("redirect_uri", `String credentials.redirect_uri);
  ] in
  let content = Yojson.Safe.pretty_to_string json in
  write_file (credentials_file ()) content;
  (* Set restrictive permissions *)
  Unix.chmod (credentials_file ()) 0o600

let load_credentials () =
  match read_file (credentials_file ()) with
  | None -> None
  | Some content ->
    try
      let json = Yojson.Safe.from_string content in
      let open Yojson.Safe.Util in
      Some {
        client_id = json |> member "client_id" |> to_string;
        client_secret = json |> member "client_secret" |> to_string;
        redirect_uri = json |> member "redirect_uri" |> to_string;
      }
    with
    | _ -> None

let save_tokens tokens =
  let json = `Assoc [
    ("access_token", `String tokens.access_token);
    ("refresh_token", match tokens.refresh_token with 
      | Some token -> `String token 
      | None -> `Null);
    ("expires_at", `Float tokens.expires_at);
  ] in
  let content = Yojson.Safe.pretty_to_string json in
  write_file (tokens_file ()) content;
  (* Set restrictive permissions *)
  Unix.chmod (tokens_file ()) 0o600

let load_tokens () =
  match read_file (tokens_file ()) with
  | None -> None
  | Some content ->
    try
      let json = Yojson.Safe.from_string content in
      let open Yojson.Safe.Util in
      Some {
        access_token = json |> member "access_token" |> to_string;
        refresh_token = (match json |> member "refresh_token" with
          | `String token -> Some token
          | _ -> None);
        expires_at = json |> member "expires_at" |> to_float;
      }
    with
    | _ -> None

let is_token_valid tokens =
  let current_time = Unix.time () in
  let buffer_time = 300.0 in (* 5 minutes buffer *)
  tokens.expires_at > (current_time +. buffer_time)

let clear_tokens () =
  let tokens_path = tokens_file () in
  if Sys.file_exists tokens_path then
    Sys.remove tokens_path

let default_credentials () = {
  client_id = "";
  client_secret = "";
  redirect_uri = "http://localhost:8080";
}

let google_auth_scope = "https://www.googleapis.com/auth/calendar.readonly"
