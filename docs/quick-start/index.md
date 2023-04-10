---
hide:
  - navigation
---

# Primate 

An expressive, minimal and extensible framework for JavaScript.

## Quick start

Generate `package.json` and `primate.config.js` by executing `npx primate@latest create -y`.

Add the Primate HTMX module to `primate.config.js`.

```js
import htmx from "@primate/htmx"

export default {
  modules: [htmx()],
};
```
<br/>

Create the index route in `routes/index.js`.

```js
import {view} from "primate";

export default {
  get: () => view("button.htmx"),
};
```
<br/>

Create another `/hello` route in `routes/hello.js`.

```js
import htmx from '@primate/htmx';

export default {
  post: () => "Hi",
};
```
<br/>

Create a button component in `components/button.htmx`.

```js
<button hx-post="/hello" hx-swap="outerHTML">
  Click me
</button>
```
<br/>

Run `npm i && npm i @primate/htmx && npm start`.
<br/><br/>

Visit <http://localhost:6161>.

## Resources

* Website: https://primatejs.com
* IRC: Join the `#primate` channel on `irc.libera.chat`.

## License

MIT

[primate-domains]: https://github.com/primatejs/primate-domains
