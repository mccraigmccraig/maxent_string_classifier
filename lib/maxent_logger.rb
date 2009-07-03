module MaxentStringClassifier
  module Logger
    class << self
      attr_accessor :logger
    end

    self.logger = ::Logger.new($stderr)
    logger.datetime_format="%Y%m%d-%H:%M.%S"
    logger.level = ::Logger::INFO

    def self.included( mod )
      # add the logger method to both instances and class
      mod.instance_eval do
        class << self
          Logger.send(:append_features, self )
        end
      end
    end

    def logger
      Logger.logger
    end
  end
end
