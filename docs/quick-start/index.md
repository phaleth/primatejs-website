---
hide:
  - navigation
---

# Primate 

An expressive, minimal and extensible framework for JavaScript.

## Quick start

Generate `primate.config.js` by executing `npx primate@latest create -y`.

Add the Primate HTMX module to `primate.config.js`.

```js
import htmx from "@primate/htmx"

export default {
  modules: [htmx()],
};
```

<br/>

Create a couple of routes in `routes/hello.js`.

```js
import htmx from '@primate/htmx';

export default (router, {htmx}) => {
  router.get('/', () => htmx('index-htmx'));
  router.post("/hello", () => "Hi");
};

```
<br/>

Create a component in `components/index-htmx.html`.

```js
<button hx-post="/hello" hx-swap="outerHTML">
  Click me
</button>

```
<br/>

Run `npm i && npm start`.
<br/><br/>

Visit <http://localhost:6161>.

## Resources

* Website: https://primatejs.com
* IRC: Join the `#primate` channel on `irc.libera.chat`.

## License

MIT

[primate-domains]: https://github.com/primatejs/primate-domains
