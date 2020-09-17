# CI/CD Pipeline built by Travis-CI, Docker and AWS ECS.

## Wordpress cache
Use wordpress cache need to install plugin, choose the `W3 Total Cache` plugin.
```
Prior to WordPress 2.5, data stored using the wp_cache functions was stored persistently if you added define('WP_CACHE', true) to your wp-config.php file. This is no longer the case, and adding the define will have no effect unless you install a persistent cache plugin (see list below). Refer to the [doc](https://codex.wordpress.org/Class_Reference/WP_Object_Cache)
```
