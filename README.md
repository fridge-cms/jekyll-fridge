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
  {{content.body | markdown}}

{% endfor %}
```
