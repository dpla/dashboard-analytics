module MetadataCompletenessHelper

  # @param num String
  # @return String percentage representation of the number
  def render_percentage(num)
    number_to_percentage(num.to_f * 100, precision: 0)
  end

  def percentage_class(num)
    "value-#{(num.to_f * 100).round.to_s}"
  end

  ##
  # Renders a percentage wrapped in a tooltip whose body shows the absolute count.
  # When item_count is nil the tooltip is omitted and a bare percentage is returned.
  #
  # @param value      [Float, nil]  the fractional value (e.g. 0.41)
  # @param item_count [Integer, nil] the total number of items
  # @return [ActiveSupport::SafeBuffer]
  def render_percentage_with_count(value, item_count)
    pct = render_percentage(value)
    return pct if item_count.nil? || item_count.to_i == 0 || value.nil?
    abs = (value.to_f * item_count.to_i).round
    content_tag(:div, class: "tooltip") do
      content_tag(:span, pct) +
        content_tag(:span,
                    "#{number_with_delimiter(abs)} of #{number_with_delimiter(item_count)} items",
                    class: "tooltiptext")
    end
  end
end
