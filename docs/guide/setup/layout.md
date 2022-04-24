# Layout 

A standard Primate application has the following directory layout.

```
client
  app.js
data
  stores
  domains
primate.json
public
routes
routes.json
server
  app.js
ssl
  default.crt
  default.key
static
  index.html
```

!!! note ""
    Only `server/app.js` and `ssl/default.{crt,key}` are required.

## client

The directory for client logic, including the entry script `app.js`,
[contexts][], [actions][] and [attributes][]. It affects how your application
behaves on the client-side.

Assuming you have a context `guest` (the default context) and an action
`author/create` in your application for which you need client-side logic, this
directory would have the following layout.

```
client
  app.js
  attributes.js
  guest
    context.js
    author
      create.js
```

!!! note ""
    The `client` directory only stores JavaScript logic. CSS, fonts or any
    other resources your client-side may have go into `static`.

### app.js

`client/app.js ` is the client-side entry script to your application. If it
doesn't exist, Primate uses a preset file.

```js
import {app} from "./primate.js";
app.run();
```

## data

The directory for your application's data layer, including stores and domains.

### stores

In `data/stores` you initialize your [stores][]. This directory should contain
`.js` files, each with an instance of a Primate `Store` class as its default
export.

!!! note ""
    Your domains will work even if you don't define any store. Primate uses its
    built-in transient in-memory store in case it can't find one.

### domains

In `data/domains` you define your [domains][]. This directory should contain
`.js` files, each with a Primate `Domain` class as its default export.

## primate.json

The [configuration][configuring] file for your application.

!!! note ""
    You don't necessarily need a `primate.json` to run Primate. It is mostly
    used to override defaults or define additional configuration options you
    might need.

!!! note ""
    We recommend adding `primate.json` to your `.gitignore`.

## public

The directory from which all content is served. Don't create any files in it as
it is recycled every time you start Primate.

!!! note ""
    During start-up, Primate copies files and directories from both `client`
    and `static` into `public`.

!!! note ""
    We recommend adding `public` to your `.gitignore`.

## routes

## server

The directory for server logic, including the entry script `app.js`,
[contexts][], [actions][] and [views][]. It affects how your application
behaves on the server-side.

Assuming you have a context `guest` (the default context) and an action
`author/create` in your application, this directory would have the following
layout.

```
server
  app.js
  guest
    context.js
    author
      create.js
      create.html
```

### app.js

`server/app.js` is the server-side entry script to your application. It should
at the least contain the following code.

```js
import {app} from "primate";
app.run();
```

Primate apps are path-based singletons. That means that the `app` export is
already wired to the current directory. Unlike most exports in Primate, it is
stateful.

!!! note ""
    Other stateful imports are `conf`, which shortcuts to `app.conf`, and
    `domains`.

## ssl

Primate only runs on HTTPS, so for local development you have to generate an
SSL key and certificate inside the `ssl` directory.

```
openssl req -x509 -out ssl/default.crt -keyout ssl/default.key -newkey rsa:2048 -nodes -sha256 -batch
```

!!! note ""
    You can override the location of the SSL key and certificate by overriding
    the `ssl.key` and `ssl.cert` in `primate.json`.

!!! note ""
    We recommend adding `ssl` to your `.gitignore`.

## static

The `static` directory contains all static client resources, including the
entry HTML file `index.html`, CSS, fonts or any other resources your
client-side may need that are not JavaScript.

This directory could have the following layout.

```
static
  index.html
  style.css
```

### index.html

`index.html` is your application entry HTML file. If it doesn't exist, Primate
uses a preset file.

```html
<!doctype html>
<html>
  <head>
    <title>Primate app</title>
    <meta charset="utf-8" />
    ${client}
  </head>
  <body></body>
</html>
```

At runtime, Primate replaces `${client}` with the actual client and framework
files.

[contexts]: /guide/application/contexts
[actions]: /guide/application/actions
[attributes]: /guide/application/attributes
[stores]: /guide/data/stores
[domains]: /guide/data/domains
[views]: /guide/application/views
[configuring]: /guide/setup/configuring
