# esbuild

This deployment module allows you to use [esbuild][esbuild] in deployment.


## Installing

```
yarn add primate-esbuild
```

## Using

Import the module in `app.js` and overwrite `app.Bundler`.

```js title="app.js"
import {app} from "primate";
import esbuild from "primate-esbuild";
app.Bundler = esbuild;
app.run();
```

## Source

[https://adaptivecloud.dev/primate/primate-esbuild]()

## License

[BSD-3-Clause]()

[esbuild]: https://esbuild.github.io/
