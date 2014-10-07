jekyll-fridge
=============

Jekyll helper for adding Fridge content to your Jekyll site.

Requirements
----

```bash
$ gem install fridge_api
```

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
{% for content in site.fridge.content %}

  <h1>{{content.title}}</h1>
  {{content.body | markdownify}}

{% endfor %}
```

Using Jekyll filters

```liquid
{% assign browsers = site.fridge.content | where:"title", "Firefox" %}
{% for browser in browsers %}
  <li>{{browser.title}}</li>
{% endfor %}

{% assign pages = site.fridge.content | sort:"title" %}
{% for page in pages %}
  <li>{{page.title}}</li>
{% endfor %}
```

Content based on type

```liquid
{% for event in site.fridge.event.content %}
  ...
{% endfor %}
```
