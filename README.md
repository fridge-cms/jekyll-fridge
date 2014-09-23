jekyll-fridge
=============

Jekyll helper for adding Fridge content to your Jekyll site.

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
{% for content in site.data.fridge.content %}

  <h1>{{content.title}}</h1>
  {{content.body | markdownify}}

{% endfor %}
```

Using Jekyll filters

```liquid
{% assign pages = site.data.fridge.content | where:"title", "page" | sort:"title" %}
{% for page in pages %}

  <li><a href="{{page.slug}}">{{page.title}}</a></li>

{% endfor %}
```
