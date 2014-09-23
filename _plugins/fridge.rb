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

  class FridgeContentWrapper
    def initialize(client, base)
      @client = client
      @base = base
    end

    def to_liquid
      content = @client.get(@base)
      content.map { |m| FridgeModelWrapper.new m }
    end
  end

  class FridgeModelWrapper
    def initialize(model)
      @model = model
    end

    def to_liquid
      # @model
      {
        'title' => @model.title
      }
    end
  end

  # class FridgeContentTag < Liquid::Tag

  #   def initialize(tag_name, markup, tokens)
  #     p markup
  #     super
  #   end

  #   def render(context)
  #     p "TEST"
  #     client = FridgeApi.client({
  #       :client_id => context.registers[:site].config['fridge']['client_id'],
  #       :client_secret => context.registers[:site].config['fridge']['client_secret']
  #     })
  #     client.get("content")
  #   end
  # end

end

# Liquid::Template.register_tag('fridge.content', Jekyll::FridgeContentTag)
