# MongoDB

This store module facades [MongoDB][mongodb], allowing you to work with
MongoDB databases.

## Requirements

MongoDB needs to be installed. On Arch Linux it is installable via the AUR. You
will typically need a AUR helper for that.

```
yay -S mongodb-bin
```

## Installing

```
yarn add primate-mongodb-store
```

## Using

Import the module and instance a store with `name` (database name) and `path`
(path to MongoDB).

```js
import MongoDBStore from "primate-mongodb-store";
export default new MongoDBStore({"name": "app", "path": "mongodb://localhost"});
```

## Source

[https://adaptivecloud.dev/primate/primate-mongodb-store]()

## License

[BSD-3-Clause]()

[mongodb]: https://mongodb.com
