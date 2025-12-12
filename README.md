# FirebaseHostingClientIp

A Rails middleware gem that normalizes client IP addresses when your Rails application is deployed behind Firebase Hosting.

## Problem

When a Rails application is deployed behind Firebase Hosting, the original client IP address is obscured by proxy layers. Rails' default `ActionDispatch::RemoteIp` middleware may not correctly identify the true client IP due to the specific header precedence used by Firebase Hosting's infrastructure.

This gem provides a middleware that implements a heuristic precedence order specifically designed for Firebase Hosting's proxy chain, ensuring `request.remote_ip` returns the correct client IP address.

## Supported Architecture

This gem is designed for the following architecture:

```
Client → Firebase Hosting → Rails Application
```

Firebase Hosting uses Fastly CDN behind the scenes (this is not a documented feature and is not configurable - all Firebase Hosting users get Fastly CDN automatically). The middleware handles the `HTTP_FASTLY_CLIENT_IP` header that Fastly provides, as well as the `HTTP_X_FORWARDED_FOR` header from the proxy chain.

## Intended Use Cases

This middleware is useful for:

- **Logging**: Accurately log client IP addresses for audit trails and debugging
- **Analytics**: Track user locations and behavior based on correct IP geolocation
- **User Experience**: Personalize content based on user location
- **Security**: Implement IP-based rate limiting or access controls

## Security Disclaimer

**IMPORTANT**: This middleware trusts HTTP headers (`HTTP_FASTLY_CLIENT_IP` and `HTTP_X_FORWARDED_FOR`) to determine the client IP address. These headers can be spoofed by clients if they have direct access to your application.

**This middleware is only safe to use when:**
- Your Rails application is deployed behind Firebase Hosting (or a trusted proxy/CDN)
- Direct access to your application is blocked (e.g., via firewall rules)
- You trust the proxy infrastructure to set these headers correctly

**Do not use this middleware if:**
- Your application is directly accessible from the internet
- You cannot guarantee that requests pass through Firebase Hosting
- You need strict security guarantees about IP address authenticity

For production deployments, ensure your application only accepts traffic through Firebase Hosting and cannot be accessed directly.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'firebase_hosting_client_ip'
```

And then execute:

```bash
bundle install
```

## Usage

The middleware is automatically loaded when Rails is detected. No additional configuration is required.

The middleware is inserted into the Rails middleware stack after `ActionDispatch::RemoteIp`, ensuring proper precedence in the request processing chain.

### Expected Behavior

After the middleware processes a request, `request.remote_ip` will return the normalized client IP address according to the following precedence:

1. `HTTP_FASTLY_CLIENT_IP` header (if present and not empty)
2. Left-most value from `HTTP_X_FORWARDED_FOR` header (if present and not empty)
3. `REMOTE_ADDR` (fallback to the value already processed by `ActionDispatch::RemoteIp`)

### Example

```ruby
class ApplicationController < ActionController::Base
  def index
    # This will return the correct client IP even behind Firebase Hosting
    client_ip = request.remote_ip
    Rails.logger.info "Request from: #{client_ip}"
  end
end
```

### Testing the Middleware

You can verify the middleware is working by checking the `request.remote_ip` value in your controllers or by inspecting the `REMOTE_ADDR` environment variable in your middleware stack.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/quintsys/firebase_hosting_client_ip. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/quintsys/firebase_hosting_client_ip/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the FirebaseHostingClientIp project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/quintsys/firebase_hosting_client_ip/blob/master/CODE_OF_CONDUCT.md).
