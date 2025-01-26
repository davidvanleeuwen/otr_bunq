defmodule OtrBunq.Client do
  @moduledoc """
  A client for interacting with the Bunq API, focusing on session management.
  """
  @api_base "https://api.bunq.com/v1"

  # Load static environment variables
  defp load_private_key do
    private_key_base64 = Application.fetch_env!(:otr_bunq, :bunq_private_key)

    private_key_base64
    |> Base.decode64!()
    |> :public_key.pem_decode()
    |> hd()
    |> :public_key.pem_entry_decode()
  end

  defp api_key, do: Application.fetch_env!(:otr_bunq, :bunq_api_key)
  def user_id, do: Application.fetch_env!(:otr_bunq, :bunq_user_id)
  def account_id, do: Application.fetch_env!(:otr_bunq, :bunq_account_id)

  @session_table :ets.new(:session_table, [:named_table, :set, :public])

  defp fetch_session_token do
    case :ets.lookup(@session_table, :session_token) do
      [{:session_token, token}] -> token
      [] -> nil
    end
  end

  defp store_session_token(token) do
    :ets.insert(@session_table, {:session_token, token})
  end

  defp sign_request(body) do
    private_key = load_private_key()

    :public_key.sign(body, :sha256, private_key)
    |> Base.encode64()
  end

  defp client_headers(body \\ "") do
    [
      {"cache-control", "no-cache"},
      {"user-agent", "OTR_bunq/1.0"},
      {"X-Bunq-Client-Request-Id", UUID.uuid4()},
      {"X-Bunq-Geolocation", "0 0 0 0 000"},
      {"X-Bunq-Language", "en_US"},
      {"X-Bunq-Region", "nl_NL"},
      {"X-Bunq-Client-Authentication", fetch_session_token()},
      {"X-Bunq-Client-Signature", sign_request(body)}
    ]
  end

  defp create_session do
    body = %{secret: api_key()} |> Jason.encode!()

    installation_token = Application.fetch_env!(:otr_bunq, :bunq_installation_token)

    headers = [
      {"X-Bunq-Client-Authentication", installation_token} | client_headers(body)
    ]

    case Req.post(@api_base <> "/session-server", body: body, headers: headers) do
      {:ok, %Req.Response{status: 200, body: %{"Response" => response}}} ->
        session_token = get_in(response, [Access.at(1), "Token", "token"])
        store_session_token(session_token)
        {:ok, session_token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp ensure_session do
    case fetch_session_token() do
      nil -> create_session()
      token -> {:ok, token}
    end
  end

  def get_account_balance do
    case ensure_session() do
      {:ok, _session_token} ->
        url = "/user/#{user_id()}/monetary-account/#{account_id()}"

        case Req.get(@api_base <> url, headers: client_headers()) do
          {:ok,
           %Req.Response{
             status: 200,
             body: %{
               "Response" => [%{"MonetaryAccountBank" => %{"balance" => %{"value" => balance}}}]
             }
           }} ->
            {:ok, balance}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end
end
