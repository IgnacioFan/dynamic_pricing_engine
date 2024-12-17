class ApplicationService
  def self.call(*args, &block)
    new(*args, &block).call
  end

  def initialize(*args, &block); end

  def success(payload = nil)
    OpenStruct.new(success?: true, payload: payload)
  end

  def failure(error)
    OpenStruct.new(success?: false, error: error)
  end
end
