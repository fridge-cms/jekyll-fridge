require 'fridge_api'

module Jekyll

  class Fridge < Generator
    safe true
    priority :low

    def generate(site)
      site.data['fridge'] = FridgeApiWrapper.new site.config['fridge']
    end
  end

  class FridgeApiWrapper

    def initialize(config)
      @client = FridgeApi.client({
        :client_id => config['client_id'],
        :client_secret => config['client_secret']
      })
    end

    def to_liquid
      {
        'content' => FridgeContentWrapper.new(@client, "content"),
        'collections' => FridgeContentWrapper.new(@client, "collections"),
        'settings' => FridgeContentWrapper.new(@client, "settings")
      }
    end

  end

  class FridgeContentWrapper < Array

    def initialize(client, base)
      @client = client
      @base = base
      super []
    end

    def to_liquid
      unless @content
        @content = @client.get(@base)
        @content.each{ |m| self << FridgeModelWrapper.new(m) }
      end
      self
    end
  end

  class FridgeModelWrapper
    def initialize(model)
      @model = model
    end

    def inspect
      @data
    end

    def to_liquid
      @data ||= Hash[@model.attrs.map{ |k, v| [k.to_s, v]}]
    end
  end

end
