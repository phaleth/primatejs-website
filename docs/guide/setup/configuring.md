# Configuring

All configuring in Primate is done in `primate.json`. As a Primate app is a
path-based singleton, the configuration is conveniently available to you as the
`{conf}` export from anywhere in your application.

```js
import {conf} from "primate";
```

!!! note ""
    `{app}`, `{conf}` (short for `app.conf`) and `{domains}` are the only
    stateful exports in Primate, the rest are all stateless.

You don't have to create a `primate.json` file for your application unless you
intend to overwrite any configuration option. Primate will start even without
an explicit configuration file, with the following values.

```json
{
  "base": "/",
  "debug": false,
  "defaults": {
    "action": "index",
    "context": "guest",
    "namespace": "default",
    "store": "default.js"
  },
  "files": {
    "index": "index.html"
  },
  "http": {
    "host": "localhost",
    "port": 9999,
    "ssl": {
      "key": "ssl/default.key",
      "cert": "ssl/default.crt"
    }
  },
  "paths": {
    "client": "client",
    "data": {
      "domains": "domains",
      "stores": "stores"
    }
    "public": "public",
    "server": "server",
    "static": "static"
  }
}
```

!!! note ""
    Overriding one of the properties of an object won't override the entire
    object. For example, if you want to change the port number your Primate
    application uses, you only need to override `http.port`.

    ```json
    {
      "http": {
        "port": 9998
      }
    }
    ```

    `http.host` will still be `localhost` and `http.ssl` will point to
    `ssl/default.{key, crt}`.

## base

Type: String
Value: /

## debug

## defaults

### action

### context

### namespace

### session

### store
