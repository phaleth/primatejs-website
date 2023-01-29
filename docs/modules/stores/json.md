# JSON

This store module facades JSON files, allowing you to work with their 
structured data.

## Installing

```
npm install primate-json-store
```

## Using

Import the module and instance a store with `name` (JSON filename) and `path`
(path to directory).

```js
import JSONStore from "primate-json-store";
export default new JSONStore({"name": "app.json", "path": "/tmp"});
```
!!! note
    A collection in this store is a keyed subobject.
    ```json
    {
      "post": [
        {"_id": "1", "title": "Last day at school", "text": "Today was ..."}
      ],
      "comment": [
        {"_id": "1", "post_id": "1", "text": "Very interesting read!"}
      ]
    }
    ```

## Source

[https://github.com/primatejs/primate-json-store]()

## License

[BSD-3-Clause]()
