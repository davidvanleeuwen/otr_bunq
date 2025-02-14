defmodule OtrBunqWeb.Home do
  use OtrBunqWeb, :live_view

  alias OtrBunq.Donations

  @donation_messages [
    "Keep OTR alive by donating to:",
    "Show some love for OTR! 💙",
    "Slushpuppies are expensive! 🥤",
    "Help us keep the lights on!",
    "Coffee keeps us going! ☕️",
    "Donate by scanning the QR code:",
    "Real hackers donate",
    "Do you have some spare change?",
    "Send your message with your donation!"
  ]

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

    # Start the 20-second interval for changing messages
    :timer.send_interval(5_000, :change_message)

    {:ok,
     assign(socket,
       show_special_image: false,
       balance: balance,
       delta: nil,
       message: nil,
       latest_donations: latest_donations,
       top_donations: top_donations,
       donation_message_index: 0,
       donation_message: List.first(@donation_messages)
     )}
  end

  def handle_info(
        %{latest_donations: latest, top_donations: top, balance: new_balance, delta: delta},
        socket
      ) do
    last_donation = hd(latest)

    message =
      if last_donation.description do
        last_donation.description
      else
        random_message(delta)
      end

    show_image = Decimal.eq?(last_donation.amount, Decimal.new("13.37"))

    if show_image do
      Process.send_after(self(), :hide_special_image, 10_000)
    end

    {:noreply,
     socket
     |> assign(:message, message)
     |> assign(:balance, new_balance)
     |> assign(:latest_donations, latest)
     |> assign(:top_donations, top)
     |> assign(:show_special_image, show_image)
     |> push_event("confetti", %{})}
  end

  def handle_info(:hide_special_image, socket) do
    {:noreply, assign(socket, :show_special_image, false)}
  end

  def handle_info(:change_message, socket) do
    next_index = rem(socket.assigns.donation_message_index + 1, length(@donation_messages))
    next_message = Enum.at(@donation_messages, next_index)

    {:noreply, assign(socket, donation_message_index: next_index, donation_message: next_message)}
  end

  defp random_message(delta) do
    Enum.random(@messages)
    |> String.replace("{@delta}", to_string(delta))
  end
end
