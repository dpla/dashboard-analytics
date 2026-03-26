##
# Mixin for GA wrapper classes that call GaResponseBuilder.
# Provides a consistent #cache_key derived from the class name and
# whatever subset of hub/contributor/event_name/dates the class uses.
# Unset instance variables (e.g. @hub in WebsiteSearchTerms) are nil
# and serialise as empty strings, keeping the key format positional.
#
# Usage: include GaCacheable in any GA wrapper class.
#
module GaCacheable
  private

  def cache_key
    [
      "ga",
      self.class.name.underscore,
      @hub,
      @contributor,
      @event_name,
      @start_date,
      @end_date
    ].map(&:to_s).join(":")
  end
end
