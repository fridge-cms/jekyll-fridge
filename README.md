jekyll-fridge
=============

Jekyll helper for adding Fridge content to your Jekyll site.

Installation
----

* Add `jekyll-fridge` to your `Gemfile`:

```Gemfile
group :jekyll_plugins do
  gem "jekyll-fridge"
end
```

* Read on to configure the plugin.

_[Not using Bundler? There are other ways..](http://jekyllrb.com/docs/plugins/)_

Usage
----

In `_config.yml`

```yaml
fridge:
  client_id: sk_xxxxxxxxxx
  client_secret: xxxxxxxxxxxx
```

In your templates

```liquid
<h1>{{site.fridge.settings.home.title}}</h1>

<nav>
  {% for item in site.fridge.navigation.content %}
    <li>{{item.title}}</li>
  {% endfor %}
</nav>

{{site.fridge.content.15.body | markdownify }}

{% for posts in site.fridge.content.blog_post %}
  <li>Post: {{post.title}}</li>
{% endfor %}
```

Using Jekyll filters

```liquid
{% assign firefoxes = site.fridge.browser.content | where:"title", "Firefox" %}
{% for browser in firefoxes %}
  <li>{{browser.title}}</li>
{% endfor %}

{% assign pages = site.fridge.content.page | sort:"title" %}
{% for page in pages %}
  <li>{{page.title}}</li>
{% endfor %}
```

Filters
------

`fridge_asset`

Finds Fridge asset based on file name. Downloads asset to `asset_dir` _(configurable. defaults to `assets`)_ and
returns a url for the file.

```liquid
{% for image in site.fridge.content.photo %}
  <img src="{{ image.name | fridge_asset }}" />
{% endfor %}
```

`fridge_choices`

Parses choices from a select/radio/checkbox content type.

```liquid
{% assign choices = site.fridge.types.blog.categories.choices %}
{% for category in choices %}
  {{category}}
{% endfor %}
```

Reference
----

* [Liquid](https://github.com/Shopify/liquid/wiki/Liquid-for-Designers)
