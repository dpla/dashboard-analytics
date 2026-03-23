##
# Mixin for GA wrapper classes that call GaResponseBuilder.
# Provides #error? and #error_message after a failed #response call.
#
# Usage: include GaErrorTracking in any class whose #response method
# rescues and returns nil on GA errors. In the rescue block, call
# record_ga_error(e) before returning nil.
#
module GaErrorTracking
  def error? = @ga_error_message.present?
  def error_message = @ga_error_message

  private

  def record_ga_error(e)
    @ga_error_message = e.message
  end
end
