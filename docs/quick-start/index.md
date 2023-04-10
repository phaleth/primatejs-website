---
hide:
  - navigation
---

# Primate 

Expressive, minimal and extensible framework for JavaScript

## Quick start

Generate `package.json` and `primate.config.js` by executing `npx primate@latest create -y`.

Add the Primate HTMX, Svelte and esbuild modules to `primate.config.js`.

```js
import htmx from '@primate/htmx';
import svelte from '@primate/svelte';
import esbuild from '@primate/esbuild';

export default {
  debug: true,
  modules: [
    svelte({entryPoints: ['Index.svelte']}), htmx(), esbuild()
  ],
};
```
<br/>

Create the index route in `routes/index.js`.

```js
import {view} from 'primate';

export default {
  get: () => view('Index.svelte'),
};
```
<br/>

Create another `/hello` route in `routes/hello.js`.

```js
export default {
  post: () => "Hi",
};
```
<br/>

Create a component in `components/Index.svelte`

```html
<script>
  let count = 0;
  const handleClick = () => {
    count++;
  };
</script>
 
<button on:click={handleClick}>
  count: {count}
</button>
<button hx-post="/hello" hx-swap="outerHTML">
  Click me
</button>

<style>
  button {
    border-radius: 4px;
    background-color: #5ca1e1;
    border: none;
    color: #fff;
    display: block;
  }
</style>
```
<br/>

Run `npm i && npm i @primate/htmx @primate/svelte @primate/esbuild && npm run dev`.
<br/><br/>

Visit <http://localhost:6161>.

## Resources

* Website: https://primatejs.com
* IRC: Join the `#primate` channel on `irc.libera.chat`.

## License

MIT
