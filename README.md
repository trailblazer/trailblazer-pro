# Trailblazer::Pro

A library to communicate with the TRAILBLAZER PRO platform.

* Push local traces to us, and analyze using the online debugger.
* Export diagrams from the PRO editor to use with the `trailblazer-workflow` gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "trailblazer-pro"
```

## Rails support

Check out the [Rails support docs](https://trailblazer.to/2.1/docs/pro) of `trailblazer-pro-rails` if you want to start web-debugging right away.

## Trace

Retrieve you API key from https://pro.trailblazer.to/settings.
It will be something like `tpka_f5c698e2_d1ac_48fa_b59f_70e9ab100604`.

## Internals

### Testing

Either run against our hosted https://test-pro-rails-jwt.onrender.com TRB PRO host, or locally. This is currently set in `test/test_helper.rb`.


* `test/no_extend` Tests an environment where no monkey-patches happened, and if, only on anonymous classes.

### Notes

* With `endpoint`, monkey-patching might become obsolete, since we can inject {:present_options} transparently.
