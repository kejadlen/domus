# frozen_string_literal: true

module Domus
  # Formats a timestamp as a compact, archival relative age —
  # "now", "5m", "3h", "2d", "1w", "4mo", "2y".
  module RelativeTime
    module_function

    def format(at, now: Time.now)
      return "" unless at

      seconds = (now - at).to_i
      return "now" if seconds < 60

      minutes = seconds / 60
      return "#{minutes}m" if minutes < 60

      hours = minutes / 60
      return "#{hours}h" if hours < 24

      days = hours / 24
      return "#{days}d" if days < 7

      weeks = days / 7
      return "#{weeks}w" if days < 30

      months = days / 30
      return "#{months}mo" if months < 12

      "#{days / 365}y"
    end
  end
end
