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

    message =
      case extract_bunq_description(last_donation.description) do
        nil -> format(random_message(delta))
        desc -> format(desc)
      end

    {:noreply,
     socket
     |> assign(:balance, new_balance)
     |> assign(:message, message)
     |> assign(
       :latest_donations,
       Enum.uniq_by([last_donation | latest], & &1.id) |> Enum.take(25)
     )
     |> assign(:top_donations, top)
     |> push_event("confetti", %{})}
  end

  defp format(description) do
    case extract_bunq_description(description) do
      # Do not escape again here
      nil -> truncate(description)
      # Do not escape again here
      desc -> truncate(desc)
    end
  end

  defp truncate(nil), do: nil

  defp truncate(text) do
    length = String.length(text)

    if length > 75 do
      max_length = 75
      text = String.slice(text, 0, max_length)

      # Keep half the text visible
      visible_length = div(max_length, 2)
      base = String.slice(text, 0, visible_length)
      extra = String.slice(text, visible_length, max_length - visible_length)

      fade_steps = String.length(extra)

      fading_effect =
        extra
        |> String.graphemes()
        |> Enum.with_index()
        |> Enum.map(fn {char, index} ->
          fade_factor = index / max(fade_steps - 1, 1)

          size = 100 - round(fade_factor * 90)
          size = if size < 10, do: 10, else: size

          opacity = Float.round(1.0 - fade_factor, 2)
          opacity = if opacity < 0, do: 0, else: opacity

          "<span style=\"font-size: #{size}%; opacity: #{opacity}\">#{char}</span>"
        end)
        |> Enum.join("")

      # Ensure correct rendering
      Phoenix.HTML.raw("#{base} #{fading_effect}")
    else
      text
    end
  end

  defp extract_bunq_description(nil), do: nil

  defp extract_bunq_description(description) do
    # Match `"text in quotes"` that comes after `"iDEAL bunq.me"`
    regex = ~r/iDEAL bunq\.me\s+"([^"]*)"/

    case Regex.run(regex, description) do
      [_, ""] -> ""
      [_, match] -> match
      _ -> nil
    end
  end

  defp random_message(delta) do
    Enum.random(@messages)
    |> String.replace("{@delta}", to_string(delta))
  end
end
