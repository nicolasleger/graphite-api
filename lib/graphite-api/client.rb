require 'forwardable'
    
module GraphiteAPI
  class Client
    extend Forwardable

    def_delegator Zscheduler, :loop, :join
    def_delegator Zscheduler, :stop

    attr_reader :options, :buffer, :connectors

    def initialize opt
      @options = build_options validate opt.clone
      @buffer  = GraphiteAPI::Buffer.new options
      @connectors = GraphiteAPI::Connector::Group.new options
      
      Zscheduler.every(options[:interval]) { send_metrics } unless options[:direct]
    end

    def every interval, &block
      Zscheduler.every( interval ) { block.arity == 1 ? block.call(self) : block.call }
    end

    def metrics metric, time = Time.now 
      return if metric.empty?
      buffer.push :metric => metric, :time => time
      send_metrics if options[:direct]
    end

    def increment(*keys)
      opt = {}
      opt.merge! keys.pop if keys.last.is_a? Hash
      by = opt.fetch(:by,1)
      time = opt.fetch(:time,Time.now)
      metric = keys.inject({}) {|h,k| h.merge k => by }
      metrics(metric, time)
    end

    def join
      sleep while buffer.new_records?
    end

    def self.default_options
      {
        :backends => [],
        :cleaner_interval => 43200,
        :port => 2003,
        :log_level => :info,
        :cache => nil,
        :host => "localhost",
        :prefix => [],
        :interval => 0,
        :slice => 60,
        :pid => "/tmp/graphite-middleware.pid"
      }
    end

    protected

    def validate options
      options.tap do |opt|
        raise ArgumentError.new ":graphite must be specified" if opt[:graphite].nil?
      end
    end

    def build_options opt
      self.class.default_options.tap do |options_hash|
        options_hash[:backends].push opt.delete :graphite
        options_hash.merge! opt
        options_hash[:direct] = options_hash[:interval] == 0
        options_hash[:slice] = 1 if options_hash[:direct]
      end
    end

    def send_metrics
      connectors.publish buffer.pull :string if buffer.new_records?
    end

  end
end
