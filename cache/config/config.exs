import Config

config :logger, :console,
       format: "$time [$level] $message $metadata\n",
       metadata: [:error_code, :request_id, :mfa, :file, :line, :pid]