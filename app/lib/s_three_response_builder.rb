class SThreeResponseBuilder

  def initialize
    @client = get_client
  end

  ##
  # @param [String] S3 key (i.e. filepath)
  #
  # @return Aws::S3::Types::GetObjectOutput
  #
  # @raise [Aws::S3::Errors::NoSuchKey]
  # The specified key does not exist. Do not retry.
  #
  # @raise [S3::Errors::InternalError]
  # An error occurred on the server and the request can be retried.
  #
  # Documentation about possible errors:
  # https://docs.aws.amazon.com/sdkforruby/api/Aws/S3/Errors.html
  #
  def response(key)
    tries ||= 0
    response = @client.get_object({ bucket: bucket, key: key })
  rescue Aws::S3::Errors::InternalError
    # Use exponential backoff to delay next request attempt.
    sleep(2**tries + rand) and retry unless(tries += 1) == 3
  end

  private

  ##
  # @return AWS::S3::Client
  def get_client
    tries ||= 0
    Aws::S3::Client.new(region: region)
  rescue Aws::S3::Errors::InternalError
    # Use exponential backoff to delay next request attempt.
    sleep(2**tries + rand) and retry unless(tries += 1) == 3
  end

  ##
  # @return String
  def bucket
    Settings.s3.bucket
  end

  ##
  # TODO: Define in config settings
  def region
    'us-east-1'
  end
end
