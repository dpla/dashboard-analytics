##
# Encodes a hub or contributor name for use as a route id.
#
# Literal slashes become %2F so the string passes Rails' [^\/]+ route
# constraint during URL generation. Rails' escape_segment then re-encodes
# the % to %25, producing %252F in the final URL.
# ApplicationController#normalize_encoded_params runs a second CGI.unescape
# on inbound params to reverse that extra layer.
#
module RouteId
  module_function

  def encode(name)
    name.to_s.gsub("/", "%2F")
  end
end
