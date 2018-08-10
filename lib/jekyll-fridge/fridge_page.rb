module Jekyll
  class FridgePage < Page
    def initialize(site, base, dir, content, config)
      @site = site
      @base = base
      @dir = dir
      @name = "index.html"

      self.process(@name)
      if content.attrs.has_key?(:template)
        self.read_yaml_from_string(content.template)
      else
        self.read_yaml(File.join(base, '_layouts'), config['layout'])
      end

      self.data[config['type']] = Jekyll::Fridge::Model.new(content)
      self.data['title'] = content.title
    end

    def read_yaml_from_string(str)
      begin
        self.content = str
        if content =~ /\A(---\s*\n.*?\n?)^((---|\.\.\.)\s*$\n?)/m
          self.content = $POSTMATCH
          self.data = SafeYAML.load($1)
        end
      rescue SyntaxError => e
        Jekyll.logger.warn "YAML Exception reading custom layout: #{e.message}"
      end

      self.data ||= {}
    end
  end

  class FridgePageGenerator < Generator
    safe true
    priority :lowest

    def generate(site)
      return if site.config['fridge_collections'].nil?

      client = site.config['fridge']
      site.config['fridge_collections'].each do |type, options|
        options = {
          'type' => type,
          'query' => "content?type=#{type}",
          'path' => type,
          'layout' => "#{type}.html"
        }.merge(options || {})

        client.get(options['query']).each do |document|
          slug = document.slug == 'index' ? '' : document.slug
          site.pages << FridgePage.new(site, site.source, File.join(options['path'], slug), document, options)
        end
      end
    end
  end
end
