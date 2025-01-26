defmodule OtrBunqWeb.Home do
  use OtrBunqWeb, :live_view

  alias OtrBunq.GenBalance

  @messages [
    "Some crazy guy just added €{@delta}! 🎉",
    "💸 A mystery millionaire dropped €{@delta} in the pot!",
    "🚀 Someone's feeling generous! €{@delta} incoming!",
    "Is it payday? Someone threw in €{@delta}! 🤑",
    "Whoa! Someone just flexed with €{@delta}! 💪",
    "💰 Cha-ching! You got €{@delta}!",
    "🤯 Someone's wallet just got lighter by €{@delta}!",
    "🎩 A magician conjured €{@delta} for you!",
    "🛸 Aliens just donated €{@delta}! 🛸",
    "💃 Someone danced their way to €{@delta}!",
    "🔥 Hot stuff! €{@delta} just appeared!",
    "🚨 Alert: €{@delta} has been added! 🚨",
    "🎁 Surprise! You just got €{@delta}!",
    "🍕 Someone skipped their pizza night for €{@delta}!",
    "🐒 A monkey just threw €{@delta} at you!"
  ]

  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(OtrBunq.PubSub, "balance:updates")

    balance = GenBalance.get_balance()
    latest_donations = GenBalance.get_latest_donations()
    top_donations = GenBalance.get_top_donations()

    {:ok,
     assign(socket,
       balance: balance,
       delta: nil,
       message: nil,
       latest_donations: latest_donations,
       top_donations: top_donations
     )}
  end

  def handle_info(%{balance: new_balance, delta: rounded_delta}, socket) do
    message = random_message(rounded_delta)

    latest_donations = GenBalance.get_latest_donations()
    top_donations = GenBalance.get_top_donations()

    {:noreply,
     socket
     |> assign(:message, message)
     |> assign(:balance, new_balance)
     |> assign(:latest_donations, latest_donations)
     |> assign(:top_donations, top_donations)
     |> push_event("confetti", %{})}
  end

  defp random_message(delta) do
    Enum.random(@messages)
    |> String.replace("{@delta}", to_string(delta))
  end
end
