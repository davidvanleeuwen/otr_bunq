defmodule OtrBunqWeb.Home do
  use OtrBunqWeb, :live_view

  alias OtrBunq.Donations

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
    Phoenix.PubSub.subscribe(OtrBunq.PubSub, "donations:updates")

    balance = Donations.get_balance()
    latest_donations = Donations.get_latest_donations()
    top_donations = Donations.get_top_donations()

    {:ok,
     assign(socket,
       balance: balance,
       delta: nil,
       message: nil,
       latest_donations: latest_donations,
       top_donations: top_donations
     )}
  end

  def handle_info(
        %{latest_donations: latest, top_donations: top, balance: new_balance, delta: delta},
        socket
      ) do
    last_donation = hd(latest)

    dbg(last_donation)

    message =
      if last_donation.description do
        extract_bunq_description(last_donation.description) || last_donation.description
      else
        random_message(delta)
      end

    {:noreply,
     socket
     |> assign(:balance, new_balance)
     |> assign(:message, message)
     |> assign(:latest_donations, Enum.take(latest, 25))
     |> assign(:top_donations, top)
     |> push_event("confetti", %{})}
  end

  defp extract_bunq_description(description) do
    # Match both standard quotes and escaped quotes
    regex = ~r/bunq\.me\s*["']([^"']+)["']/

    case Regex.run(regex, description) do
      # Return the matched quoted part
      [_, match] -> match
      # Return nil if there's no match
      _ -> nil
    end
  end

  defp random_message(delta) do
    Enum.random(@messages)
    |> String.replace("{@delta}", to_string(delta))
  end
end
