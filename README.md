jekyll-fridge
=============

Jekyll helper for adding Fridge content to your Jekyll site.

Requirements
----

```bash
$ gem install fridge_api
```

Installation
----

* Put `fridge.rb` in your `_plugins` folder.
* Make sure you have the `fridge_api` gem installed.
* Read on to configure the plugin.

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

~~`where` filter currently depends on https://github.com/jekyll/jekyll/pull/2986~~

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
