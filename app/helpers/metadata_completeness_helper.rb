module MetadataCompletenessHelper

  # @param num String
  # @return String percentage representation of the number
  def render_percentage(num)
    number_to_percentage(num.to_f * 100, precision: 0)
  end

  def percentage_class(num)
    "value-#{(num.to_f * 100).round.to_s}"
  end
end
