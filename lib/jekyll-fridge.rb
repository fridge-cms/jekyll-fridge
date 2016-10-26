require 'fridge_api'
require 'ostruct'
require 'jekyll-fridge/fridge_page'
require 'jekyll-fridge/fridge_filters'

module Jekyll

  class FridgeGenerator < Generator
    safe true
    priority :high

    def generate(site)
      # Reset cache if client already exists
      if site.config['fridge'].kind_of?(Fridge::Client)
        site.config['fridge'].reset!()
        return
      end

      # get api configuration from _config.yml
      #
      # fridge:
      #   client_id: sk_xxxx
      #   client_secret: xxxx
      api_config = site.config['fridge']
      api_config['asset_dir'] ||= 'assets'

      # set site.fridge as plugin entry
      site.config['fridge'] = Fridge::Client.new api_config
    end
  end

  module Fridge
    # Recursively convert hash keys to strings
    def self.stringify_keys_deep(h)
      case h
      when Hash
        Hash[
          h.map do |k, v|
            [ k.respond_to?(:to_s) ? k.to_s : k, self.stringify_keys_deep(v) ]
          end
        ]
      when Sawyer::Resource
        if self.is_fridge_object?(h)
          Model.new(FridgeApi::Model.new(h.to_h))
        else
          self.stringify_keys_deep(h.to_h)
        end
      when Enumerable
        h.map { |v| self.stringify_keys_deep(v) }
      else
        h
      end
    end

    # check if an object is fridge-like
    def self.is_fridge_object?(obj)
      obj.respond_to?("key?") && (obj.key?(:id) && obj.key?(:document_definition_id))
    end

    class Client < Liquid::Drop
      attr_reader :client, :config

      def initialize(config)
        @client = FridgeApi.client({
          :client_id => config['client_id'],
          :client_secret => config['client_secret']
        })
        @config = config.delete_if { |k, v| k.to_s.match(/secret/) || v.to_s.match(/sk/) }
        reset!()
      end

      def get(path)
        return @cache[path] if @cache.has_key?(path)
        @cache[path] = @client.get(path)
      end

      def reset!
        @cache = Hash.new
      end

      def before_method(method)
        # try content type
        type = get("types/#{method}")
        if type && type.kind_of?(FridgeApi::Model)
          return Jekyll::Fridge.stringify_keys_deep(type.attrs.merge({
            'content' => ContentDrop.new(self, "content", "type=#{type.slug}")
          }))
        end

        # try user role
        role = get("roles/#{method}")
        if role && role.kind_of?(FridgeApi::Model)
          return Jekyll::Fridge.stringify_keys_deep(role.attrs.merge({
            'users' => ContentDrop.new(self, "users", "role=#{role.slug}")
          }))
        end

        nil
      end

      def content
        ContentDrop.new(self, "content")
      end

      def collections
        ContentDrop.new(self, "collections")
      end

      def settings
        ContentDrop.new(self, "settings")
      end

      def types
        ContentDrop.new(self, "types")
      end

      def users
        ContentDrop.new(self, "users")
      end

    end

    class ContentDrop < Liquid::Drop
      include Enumerable

      def initialize(client, base, query = "", data = nil)
        @client = client
        @base = base
        @query = query
        @data = data
      end

      def before_method(method)
        # check for single content item
        item = @client.get("#{@base}/#{method}?#{@query}")
        return Model.new(item) if item && item.kind_of?(FridgeApi::Model)

        # filter by content type
        if @base == "content" && @query.empty?
          types = @client.get("#{@base}?type=#{method}")
          return ContentDrop.new(@client, @base, "type=#{method}", types) if types
        end

        # filter by user role
        if @base == "users" && @query.empty?
          roles = @client.get("#{@base}?role=#{method}")
          return ContentDrop.new(@client, @base, "role=#{method}", roles) if roles
        end

        nil
      end

      def each &block
        @data ||= @client.get("#{@base}?#{@query}")
        @data.each do |v|
          m = Model.new v
          if block_given?
            block.call m
          else
            yield m
          end
        end
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
        @data ||= Jekyll::Fridge.stringify_keys_deep(@model.attrs)
      end
    end
  end
end

