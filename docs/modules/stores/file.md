# File

This store module facades file-system operations, allowing you to work with
binary files.

## Installing

```
yarn add primate-file-store
```

## Using

Import the module and instance a store with `path` (path to directory).

```js
import FileStore from "primate-file-store";
export default new FileStore({"path": "/tmp/file-store"});
```

!!! note
    A collection in this store is a subdirectory within the path, and filenames
    serve as ids.

## Source

[https://adaptivecloud.dev/primate/primate-file-store]()

## License

[BSD-3-Clause]()
