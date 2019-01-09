class SThreeResponseBuilder

  ##
  # @param [String] S3 key (i.e. filepath)
  #
  # @return [Aws::S3::Types::GetObjectOutput]
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
  def self.response(key)
    self.client.get_object({ bucket: self.bucket, key: key })
  end

  def self.list(prefix)
    self.client.list_objects({ bucket: self.bucket, prefix: prefix })
  end

  private

  def self.client
    # TODO: Define region in config settings
    # By default, the client retries 500 and some 400 errors three times.
    @@client ||= Aws::S3::Client.new(region: 'us-east-1')
  end

  ##
  # @return String
  def self.bucket
    Settings.s3.bucket
  end
end
