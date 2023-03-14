---
hide:
  - navigation
---

# Primate 

An expressive, minimal and extensible framework for JavaScript.

## Quick start

Create a couple of routes in `routes/hello.js`.

```js
import htmx from '@primate/htmx';

export default router => {
  router.get('/', () => htmx`<index-htmx />`); 
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

Generate `package.json` by executing `npm init -y`.

Add `{"type": "module"}` to the `package.json`.

Run `npm i @primate/htmx && npx primate@latest -y`.
<br/><br/>

Visit <http://localhost:6161>.

## Resources

* Website: https://primatejs.com
* IRC: Join the `#primate` channel on `irc.libera.chat`.

## License

MIT

[primate-domains]: https://github.com/primatejs/primate-domains
