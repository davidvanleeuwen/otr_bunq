defmodule OtrBunqWeb.WebhookController do
  use OtrBunqWeb, :controller

  alias OtrBunq.Donations

  @allowed_cidr "185.40.108.0/22"

  plug :verify_bunq_ip

  def receive_webhook(conn, %{"NotificationUrl" => %{"object" => %{"Payment" => payment}}}) do
    account_id = payment["monetary_account_id"]

    if account_id == OtrBunq.Client.account_id() do
      {:ok, created, _} = DateTime.from_iso8601(payment["created"] <> "Z")

      Donations.add_donation(%{
        amount: Decimal.new(payment["amount"]["value"]),
        bunq_payment_id: payment["id"],
        description: payment["description"],
        created: created |> DateTime.truncate(:second)
      })
    end

    send_resp(conn, 200, "OK")
  end

  defp verify_bunq_ip(conn, _opts) do
    real_ip = extract_real_ip(conn)

    if ip_in_cidr?(real_ip, @allowed_cidr) do
      conn
    else
      conn |> send_resp(403, "Unauthorized") |> halt()
    end
  end

  defp extract_real_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [ips | _] ->
        ips
        |> String.split(",")
        |> List.first()
        |> String.trim()

      _ ->
        Tuple.to_list(conn.remote_ip) |> Enum.join(".")
    end
  end

  defp ip_in_cidr?(ip, cidr) do
    with cidr_struct <- CIDR.parse(cidr),
         {:ok, true} <- CIDR.match(cidr_struct, ip) do
      true
    else
      _ ->
        false
    end
  end
end
