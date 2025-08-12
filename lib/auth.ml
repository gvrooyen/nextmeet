open Lwt.Syntax
open Config

let google_auth_url = "https://accounts.google.com/o/oauth2/v2/auth"
let google_token_url = "https://oauth2.googleapis.com/token"

let generate_state () =
  let bytes = Bytes.create 16 in
  for i = 0 to 15 do
    Bytes.set_uint8 bytes i (Random.int 256)
  done;
  Base64.encode_string (Bytes.to_string bytes)

let build_auth_url credentials state =
  let params = [
    ("client_id", [credentials.client_id]);
    ("redirect_uri", [credentials.redirect_uri]);
    ("response_type", ["code"]);
    ("scope", [google_auth_scope]);
    ("access_type", ["offline"]);
    ("prompt", ["consent"]);
    ("state", [state]);
  ] in
  let uri = Uri.make ~scheme:"https" ~host:"accounts.google.com" ~path:"/o/oauth2/v2/auth" () in
  Uri.with_query uri params

let start_callback_server port =
  let callback_result = ref None in
  let server_promise, server_resolver = Lwt.wait () in
  
  let callback _conn req _body =
    let uri = Cohttp.Request.uri req in
    let query = Uri.query uri in
    
    let get_param name = 
      match List.assoc_opt name query with
      | Some [value] -> Some value
      | _ -> None
    in
    
    let response_body = match get_param "code", get_param "state" with
      | Some code, Some state ->
        callback_result := Some (Ok (code, state));
        "Authentication successful! You can close this window."
      | Some _, None ->
        callback_result := Some (Error "Missing state parameter");
        "Authentication failed: Missing state parameter"
      | None, _ ->
        let error = get_param "error" |> Option.value ~default:"unknown_error" in
        callback_result := Some (Error ("Authentication failed: " ^ error));
        "Authentication failed: " ^ error
    in
    
    Lwt.wakeup server_resolver ();
    let headers = Cohttp.Header.init_with "Content-Type" "text/html" in
    Cohttp_lwt_unix.Server.respond_string ~status:`OK ~headers ~body:response_body ()
  in
  
  let _server = Cohttp_lwt_unix.Server.create ~mode:(`TCP (`Port port)) 
    (Cohttp_lwt_unix.Server.make ~callback ()) in
  
  let* () = server_promise in
  Lwt.return !callback_result

let exchange_code_for_tokens credentials code =
  let body = [
    ("client_id", credentials.client_id);
    ("client_secret", credentials.client_secret);
    ("code", code);
    ("grant_type", "authorization_code");
    ("redirect_uri", credentials.redirect_uri);
  ] in
  
  let body_string = Uri.encoded_of_query (List.map (fun (k, v) -> (k, [v])) body) in
  let headers = Cohttp.Header.init_with "Content-Type" "application/x-www-form-urlencoded" in
  
  let* response, body = Cohttp_lwt_unix.Client.post 
    ~headers
    ~body:(`String body_string) 
    (Uri.of_string google_token_url) in
  
  let* body_string = Cohttp_lwt.Body.to_string body in
  
  match Cohttp.Response.status response with
  | `OK ->
    (try
      let json = Yojson.Safe.from_string body_string in
      let open Yojson.Safe.Util in
      let access_token = json |> member "access_token" |> to_string in
      let refresh_token = json |> member "refresh_token" |> to_string_option in
      let expires_in = json |> member "expires_in" |> to_int in
      let expires_at = Unix.time () +. (float_of_int expires_in) in
      
      let tokens = {
        access_token;
        refresh_token;
        expires_at;
      } in
      
      Lwt.return (Ok tokens)
    with
    | Yojson.Json_error msg -> Lwt.return (Error ("JSON parse error: " ^ msg))
    | exn -> Lwt.return (Error ("Token exchange error: " ^ Printexc.to_string exn)))
  | status ->
    Lwt.return (Error ("HTTP error: " ^ (Cohttp.Code.string_of_status status) ^ " - " ^ body_string))

let refresh_access_token credentials refresh_token =
  let body = [
    ("client_id", credentials.client_id);
    ("client_secret", credentials.client_secret);
    ("refresh_token", refresh_token);
    ("grant_type", "refresh_token");
  ] in
  
  let body_string = Uri.encoded_of_query (List.map (fun (k, v) -> (k, [v])) body) in
  let headers = Cohttp.Header.init_with "Content-Type" "application/x-www-form-urlencoded" in
  
  let* response, body = Cohttp_lwt_unix.Client.post 
    ~headers
    ~body:(`String body_string) 
    (Uri.of_string google_token_url) in
  
  let* body_string = Cohttp_lwt.Body.to_string body in
  
  match Cohttp.Response.status response with
  | `OK ->
    (try
      let json = Yojson.Safe.from_string body_string in
      let open Yojson.Safe.Util in
      let access_token = json |> member "access_token" |> to_string in
      let expires_in = json |> member "expires_in" |> to_int in
      let expires_at = Unix.time () +. (float_of_int expires_in) in
      
      let tokens = {
        access_token;
        refresh_token = Some refresh_token;
        expires_at;
      } in
      
      Lwt.return (Ok tokens)
    with
    | Yojson.Json_error msg -> Lwt.return (Error ("JSON parse error: " ^ msg))
    | exn -> Lwt.return (Error ("Token refresh error: " ^ Printexc.to_string exn)))
  | status ->
    Lwt.return (Error ("HTTP error: " ^ (Cohttp.Code.string_of_status status) ^ " - " ^ body_string))

let open_browser url =
  let cmd = match Sys.os_type with
    | "Unix" | "Cygwin" -> "xdg-open"
    | "Win32" -> "start"
    | _ -> "open"
  in
  ignore (Sys.command (cmd ^ " '" ^ (Uri.to_string url) ^ "'"))

let authenticate ?(silent=false) credentials =
  let state = generate_state () in
  let auth_url = build_auth_url credentials state in
  
  if not silent then (
    Printf.printf "Opening browser for authentication...\n";
    Printf.printf "If the browser doesn't open, visit: %s\n" (Uri.to_string auth_url);
    flush stdout;
  );
  
  open_browser auth_url;
  
  if not silent then (
    Printf.printf "Starting local server on port 8080...\n";
    flush stdout;
  );
  
  let* result = start_callback_server 8080 in
  
  match result with
  | Some (Ok (code, received_state)) ->
    if String.equal state received_state then (
      if not silent then (
        Printf.printf "Exchanging authorization code for tokens...\n";
        flush stdout;
      );
      let* token_result = exchange_code_for_tokens credentials code in
      (match token_result with
      | Ok tokens ->
        save_tokens tokens;
        if not silent then Printf.printf "Authentication successful!\n";
        Lwt.return (Ok tokens)
      | Error msg ->
        Lwt.return (Error ("Token exchange failed: " ^ msg)))
    ) else (
      let error = "State parameter mismatch (CSRF protection)" in
      Lwt.return (Error ("Authentication failed: " ^ error))
    )
  | Some (Error msg) ->
    Lwt.return (Error ("Authentication failed: " ^ msg))
  | None ->
    let error = "No authentication response received" in
    Lwt.return (Error ("Authentication failed: " ^ error))

let get_valid_tokens ?(silent=false) () =
  match load_credentials () with
  | None ->
    let error_msg = if not silent then (
      Printf.eprintf "No Google OAuth2 credentials found.\n";
      Printf.eprintf "Please set up your credentials first.\n";
      Printf.eprintf "Create a Google Cloud Project and OAuth2 credentials, then save them to:\n";
      Printf.eprintf "%s\n" (credentials_file ());
      "No credentials configured"
    ) else "No credentials configured" in
    Lwt.return (Error error_msg)
  | Some credentials ->
    (match load_tokens () with
    | Some tokens when is_token_valid tokens ->
      Lwt.return (Ok tokens)
    | Some tokens ->
      (match tokens.refresh_token with
      | Some refresh_token ->
        let* result = refresh_access_token credentials refresh_token in
        (match result with
        | Ok new_tokens ->
          save_tokens new_tokens;
          Lwt.return (Ok new_tokens)
        | Error _msg ->
          authenticate ~silent credentials)
      | None ->
        authenticate ~silent credentials)
    | None ->
      authenticate ~silent credentials)
