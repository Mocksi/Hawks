# Hawksi

## Overview

Hawksi sits between your application and the Mocksi API, allowing our agents to learn from your app to simulate whatever you can imagine.

## Features

### Request Interception


#### Modules

- **RequestInterceptor**
  - **Description**: Middleware for intercepting and logging incoming HTTP requests and outgoing HTTP responses.
  - **Actions**:
    - `intercept_request`: Captures the request before forwarding it to the application.
    - `intercept_response`: Captures the response before sending it back to the client.
    - `log_request_response`: Stores logged data locally for future analysis.

### Storage

Intercepted calls are stored in a fast, thread-safe, filesystem-based storage system. Future integration with PostgreSQL is planned but not yet implemented.

#### Modules

- **FileStorage**
  - **Description**: Stores requests and responses as JSON files in a structured directory format on the local filesystem.
  - **Directory Structure**:
    - Base Directory: `./mocksi/interceptor`
    - Sub Directories:
      - `requests/`
      - `responses/`
  - **Concurrency**:
    - **ThreadedWriting**: Utilizes a background thread for file writing operations to maintain high performance and avoid blocking the main application flow.

### CLI

Provides a basic command-line interface for managing the HawksiInterceptor server and accessing stored requests.

#### Commands

- `start_server`: Starts the Hawksi Interceptor server.
- `stop_server`: Stops the Hawksi Interceptor server.
- `list_requests`: Lists recent intercepted requests.
- `clear_data`: Clears stored request/response data.

## Getting Started

To get started with Hawksi, ensure you have Ruby installed on your system. Then, install Hawksi by adding it to your Gemfile:

```ruby
gem 'hawksi'
```

Run `bundle install` to install Hawksi along with its dependencies. Once installed, you can start the HawksiInterceptor server using the CLI:

```bash
hawksi start
```

For more detailed instructions and usage examples, refer to the [documentation](https://github.com/Mocksi/hawksi).

## License

Hawksi is released under the MIT license. See the [LICENSE](LICENSE) file for details.