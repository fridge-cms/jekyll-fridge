require 'fridge_api'
require 'ostruct'

module Jekyll

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

  class Fridge < Generator
    safe true
    priority :high

    def generate(site)
      # Reset cache if client already exists
      if site.config['fridge'].kind_of?(Client)
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
      site.config['fridge'] = Client.new api_config
    end
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
        return Jekyll.stringify_keys_deep(type.attrs.merge({
          'content' => ContentDrop.new(self, "content", "type=#{type.slug}")
        }))
      end

      # try user role
      role = get("roles/#{method}")
      if role && role.kind_of?(FridgeApi::Model)
        return Jekyll.stringify_keys_deep(role.attrs.merge({
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
      @data ||= Jekyll.stringify_keys_deep(@model.attrs)
    end
  end

  module FridgeFilters
    # Filter for fetching assets
    # Writes static file to asset_dir and returns absolute file path
    def fridge_asset(input)
      return input unless input
      if input.respond_to?('first')
        input = input.first['name']
      end
      site = @context.registers[:site]
      asset_dir = site.config['fridge'].config['asset_dir']
      dest_path = File.join(site.dest, asset_dir, input)
      path = File.join(asset_dir, input)

      # Check if file already exists
      if site.keep_files.index(path) != nil
        return "/#{path}"
      end

      asset = site.config['fridge'].client.get("content/upload/#{input}")
      return input unless asset

      # play for keeps
      # this is so jekyll won't clean up the file
      site.keep_files << Regexp.escape(path)

      # write file to destination
      FileUtils.mkdir_p(File.dirname(dest_path))
      File.write(dest_path, asset)
      "/#{path}"
    end

    def fridge_choices(input)
      arr = input.is_a?(String) ? input.lines : input
      arr.map do |line|
        key, value = line.split ":"
        value = key if value.nil? || !value
        { "key" => key.strip, "value" => value.strip }
      end
    end
  end

end

Liquid::Template.register_filter(Jekyll::FridgeFilters)
