module Jekyll
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
      site.keep_files << path

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

  Liquid::Template.register_filter(Jekyll::FridgeFilters)
end

