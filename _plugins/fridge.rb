require 'fridge_api'

module Jekyll

  class Fridge < Generator
    safe true
    priority :low

    def generate(site)
      # get api configuration from _config.yml
      #
      # fridge:
      #   client_id: sk_xxxx
      #   client_secret: xxxx
      api_config = site.config['fridge']

      # set site.fridge as plugin entry
      site.config['fridge'] = Client.new api_config
    end
  end

  class Client

    def initialize(config)
      @client = FridgeApi.client({
        :client_id => config['client_id'],
        :client_secret => config['client_secret']
      })
    end

    def types
      @types ||= @client.get("types")
      Hash[@types.map { |type|
        [type.slug, type.attrs.merge({
          'content' => FridgeContent.new(@client, "content?type=#{type.slug}")
        })]
      }]
    end

    def to_liquid
      {
        'content' => FridgeContent.new(@client, "content"),
        'collections' => FridgeContent.new(@client, "collections"),
        'settings' => FridgeSettings.new(@client)
      }.merge(types)
    end

  end

  class FridgeContent < Array

    def initialize(client, base)
      @client = client
      @base = base
      super []
    end

    def to_liquid
      unless @content
        @content = @client.get(@base)
        @content.each{ |m| self << Model.new(m) }
      end
      self
    end
  end

  class FridgeSettings
    def initialize(client)
      @client = client
    end

    def settings
      @settings ||= @client.get("settings")
    end

    def to_liquid
      Hash[settings.map{ |set| [set.slug, Model.new(set)]}]
    end
  end

  class Model
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
