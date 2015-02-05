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
      self.stringify_keys_deep(h.to_h)
    when Enumerable
      h.map { |v| self.stringify_keys_deep(v) }
    else
      h
    end
  end

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
      @config = config.delete_if { |k, v| k.to_s.match(/client/) }
    end

    def before_method(method)
      # try content type
      type = @client.get("types/#{method}")
      if type && type.kind_of?(FridgeApi::Model)
        return Jekyll.stringify_keys_deep(type.attrs.merge({
          'content' => ContentDrop.new(@client, "content", "type=#{type.slug}")
        }))
      end

      # try user role
      role = @client.get("roles/#{method}")
      if role && role.kind_of?(FridgeApi::Model)
        return Jekyll.stringify_keys_deep(role.attrs.merge({
          'users' => ContentDrop.new(@client, "users", "role=#{role.slug}")
        }))
      end

      nil
    end

    def content
      ContentDrop.new(@client, "content")
    end

    def collections
      ContentDrop.new(@client, "collections")
    end

    def settings
      ContentDrop.new(@client, "settings")
    end

    def types
      ContentDrop.new(@client, "types")
    end

    def users
      ContentDrop.new(@client, "users")
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
      @data ||= @client.get(@base)
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
      site = @context.registers[:site]
      asset_dir = site.config['fridge'].config['asset_dir']
      dest_path = File.join(site.dest, asset_dir, input)

      asset = site.config['fridge'].client.get("content/upload/#{input}")
      return input unless asset

      path = File.join(asset_dir, input)
      # play for keeps
      # this is so jekyll won't clean up the file
      site.keep_files << path

      # write file to destination
      FileUtils.mkdir_p(File.dirname(dest_path))
      File.write(dest_path, asset)
      "/#{path}"
    end
  end

  def fridge_choices(input)
    input.lines
  end

end

Liquid::Template.register_filter(Jekyll::FridgeFilters)
