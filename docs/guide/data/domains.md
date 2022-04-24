# Domains

Domains represent a data collection. They are usually backed by a store that
takes care of the low-level operations of saving, retrieving and deleting
information. One of the common stores is the MongoDB store
([primate-mongodb-store][mongodb-store]), but a collection can be anything as
long as the underlying store implements the necessary data retrieval and
manipulation methods. Another common store is the File store
([primate-file-store][file-store]), dealing with binary data. You can even write
your ad-hoc store to be used as part of your application. Primate's test
suite [Stick][stick] uses the built-in memory store which performs all
operations in memory for flexible replayablility.

Chart 1: Relationship between Stores, Domains, and Documents.

!!! note ""
    Domains are defined under `data/domains` unless [configured
    otherwise][defaults].

## Documents and fields

Consider the following `Author` domain.

```js title="data/domains/Author.js"
import {Domain} from "primate";

export default class Author extends Domain {
  static get fields() {
    return {
      "name": String,
    };
  }
}
```

It describes a simple domain that represents a book author. Right now we're only
concerned with his name, so we've defined a field `name` of type `String`. We
can now create our first object of the class `Author`.

```js
const kipling = new Author({"name": "Rudyard"});
console.log(kipling.name);
-> Rudyard
kipling.name = "Rudyard Kipling";
```

!!! note "Documents"
    Instances of a domain are called a **document**. Once saved, they represent
    a store document in the collection bearing the same name (in lowercase) as
    the domain class name.

The last example shouldn't be surprising and corresponds to ES semanics of
object creation and manipulation. But documents in Primate also operate on their
underlying store.

```js
await kipling.save();
console.log(kipling);
-> Author {"name": "Rudyard Kipling", "_id": "60ca4e9734bce5a75816070d"}
```

This saved the `Author` document into the store's `author` collection, 
generating thereby an `_id`. Unless `_id` is set, Primate assumes that you're
creating a new document and randomly generates it for you. The semantics of
the `_id` field are that of a UUID version 4 string unless overwritten. For more
information about how ids work, see [dealing with ids][dealing-with-ids].

!!! note "Fields"
    Properties of a document that can be verified are called a **field**.

If you know the id, you can retrieve a document using the static method `one`

```js
const kipling = await Author.one("60ca4e9734bce5a75816070d");
console.log(kipling);
-> Author {"name": "Rudyard Kipling", "_id": "60ca4e9734bce5a75816070d"}
```

If you're looking to get all the documents of a domain, use the `find` method.

```js
const authors = await Author.find();
console.log(authors);
-> [Author {"name": "Rudyard Kipling", "_id": "60ca4e9734bce5a75816070d"}]
```

Say that we now want to add books to our application. We can start by defining
our next domain, `Book`.

```js title="data/domains/Book.js"
import {Domain} from "primate";
import Author from "./Author.js";

export default class Book extends Domain {
  static get fields() {
    return {
      "title": String,
      "text": String,
      "author_id": Author,
      "publishing_year": [String, "length:4"],
      "created": value => value ?? new Date(),
    };
  };
}
```

This example is a bit more contrived. `title` and `text` should be
straightforward, but what is the essence of `author_id` being of type `Author`,
and why is `publishing_year` defined using an array and `created` using a
function?

These field definitions showcase the three *implicit* ways to define the
possible values a field can have: a constructible object (class), an array, or a
non-constructible function.

!!! note ""
    In field definitions, we use the primitive wrapper objects (`String`,
    `Number` and so on) for primitives, as ES primitives aren't objects that can
    be assigned by reference.

## Defining fields

### With a constructible object (class)

```js
"field_name": ConstructibleObject
```

This is the most simple syntax and for primitive wrapper objects like `String`
or `Number` (or any constructible object that extends `Primate.Storeable`) it
just represents a *predicate*. Predicates are verification rules for fields,
and they are evaluated whenever you try to `save` (or `verify`) a document. It
is important to understand that Primate doesn't automatically check a field's
predicate when you change a document's property. You can toy around with a
document, set different values to its properties, and Primate won't interfere.
It will only refuse to verify or save a document which contains unfulfilled
predicates.

In other words, predicates are safeguards for *storeable* data.

!!! note ""
    `Domain.prototype.save` calls `Domain.prototype.verify` internally
    before saving and only saves if it passes. That means that in most cases
    when you intend to save anyway, you don't need to call `verify` before. 
    Also, `save` will forward `verify`'s return value (`true` for success,
    `false` for failure).

So `"title": String` means we can only save strings into the field `title` in
our `author` collection, and the same goes for `text`. What about `author_id`?

```js
"foreign_domain_id": ForeignDomain
```

In the case of domains used as types, Primate does a different check when you
try to save the document. In our example it expects the field `author_id` of
a `Book` instance to contain the id of an author in the `author` collection. If
it doesn't, the verification (and thus the save) will fail.

But specifying a `Domain` class as a definition value has another useful effect.
It creates a domain getter (we call this an [ad-hoc getter][ad-hoc-getters])
corresponding to the name of the field without `_id`, and this getter will
contain an (`await`able) dereference of the foreign document.

```js
const jungle_book = new Book({
  "title": "The Jungle Book",
  "text": "The ...",
  "author_id": "60ca4e9734bce5a75816070d",
  "publishing_year": "1894",
});
await jungle_book.save();
console.log(await jungle_book.author);
-> Author {"name": "Rudyard Kipling", "_id": "60ca4e9734bce5a75816070d"}
```

!!! note ""
    You don't actually have to verify or save `jungle_book` for the `author`
    getter to work, but it makes sense in most cases.


As we will see later in the section on [views], these automatically generated
getters can be used pretty cleverly to pull in information into views.

### With an array

```js
"field_name": [ConstructibleObject, "predicate_name"]
```

Sometimes it is not enough to specify just a constructible object in order to
delimit a field's possible value space. You might be thinking of various
limitations you want to enforce: the length of a string, the size of a number,
the uniqueness of a field within a collection and so on. To this end you can
use an array in the field definition. One important point to keep in mind here
is that you still need to specify the type of the field as a constructible
object, and it has to be the first item of the array (strictly, the item at
position 0). To go back to our example,

```js
"publishing_year": [String, "length:4"]
```

specifies that `publishing_year` must be a string of 4 characters. Strings of a
different length will not be accepted in verification. This obviously very much
limits the value space of this given field, and it is exactly what we want for
years.

!!! note "Predicate spaces"
    Predicates can represent a **function space** instead of a single
    function, such as in the case of `length` as defined for `String`, which has
    an integer as its first (and only) parameter. `length:0`, `length:1` and
    `length:n`, with n being a positive integer, are all valid functions in this
    predicate space.

Say that for some reason we wanted to limit the book collection to just one book
per year, all other things being equal. We could thus specify

```js
"publishing_year": [String, "length:4", "unique"]
```

Predicates are checked in the order that they are specified and verification
stops at the first error (per field).

!!! note ""
    This syntax reads very much like the English sentence *'Publishing
    year' must be a string of four characters that is unique*. One of the design
    goals of verification in Primate was to read naturally and in a concise way.

This guide includes a a full list of [built-in predicates][built-in-predicates]
and their parameters. Additionally, we will later get to
[custom predicates](#custom-predicates).

### With a non-constructible function

```js
"field_name": value => value
```

The third way to define fields implicitly is with a non-constructible function.
It is important that this function is not constructible for the fact that
if it were, Primate would assume it belonged to the first category of definition
and verify it by type. To go back to our example,

```js
"created": value => value ?? new Date()
```

means *before verification, take whatever value the property*
`created` *currently has, and run it through the anonymous function, taking the
function's output and using it as the input for verification*.

!!! note "In-functions"
    Such a function is also called an **in-function** in Primate, as it is
    executed before a value is put into the store. It is generally a pure
    function, but it can access the whole document using its second parameter
    `document`. This allows in-functions to rely on the rest of the document for
    determining the output of the given field.

You might be wondering what *verification* means in this context, as we haven't
defined any type for this field. In this case, Primate will do
something rather extraordinarily: it will call (when your application is
initialized) the function without any parameters, and use the resulting output's
type as the type for the field. For our example, the nullish coalescing
operator (`??`) in the function body means the returned output will be a `Date`
(`undefined ?? new Date()` evaluates to `new Date()`), and this is the type
Primate will use for this field in verification for any given `Book` document. For
the sake of transparency, if you activate debugging in Primate, it will tell you
in startup for every thus defined field what type it has assigned to it.

!!! note "Default values"
    An in-function combined with the `??` operator is an elegant way to set
    a default value for a field in verification. If the left operand is
    meaningful (not `undefined` and `null`), it will be used, representing an
    already existing value. Otherwise,the right operand will be used, which is
    the default value.

## Using explicit syntax to define fields

Sometimes the three implicit options described above won't be enough for you.
Perhaps, for example, you need a combination of predicates and an in-function.
In this case Primate offers you an explicit way to define fields.

```js title="data/domains/Book.js"
import {Domain} from "primate";
import Author from "./Author.js";

export default class Book extends Domain {
  static get fields() {
    return {
      "title": String,
      "text": [String], // this is equivalent to just String
      "author_id": Author,
      // explicit
      "publishing_year": {
        "type": String,
        "predicates": ["length:4"],
      }
      // also explicit
      "created": {
        "type": Date,
        "in": value => value ?? new Date(),
      }
    };
  };
}
```

That example illustrates that you can combine implicit and explicit syntax to
define different fields within the same document, and also how the explicit syntax works,
using an object with the following properties.

```js
{
  "type": ConstructibleType,                     // required
  "predicates": ["predicate_1", "predicate_n"],  // optional
  "in": value => value,                          // optional
}
```

While the `predicates` and `in` properties are optional, you must specify a type
in this syntax (as a constructible object).

## Subdocuments in fields

Sometimes you don't want to use references and prefer embedding subdocuments
within your document. To this end you can define subdocuments as `Array` or
`Object`.

```js title="data/domains/Book.js"
import {Domain} from "primate";
import Author from "./Author.js";
import Publisher from "./Publisher.js";

export default class Book extends Domain {
  static get fields() {
    return {
      "title": String,
      "text": String,
      "authors_ids": [Array, [Author]],
      "editions": [Array, [{
        "year": [String, "length:4"],
        "publisher_id": Publisher,
        "sales": Integer,
      }]],
      "lending_status": [Object, {
        "lent": Boolean,
        "date": Date,
      }],
    };
  };
}
```

In that example, we've made it possible for books to have more than one author.
`authors_ids` is defined as a array of `Author` ids, so an array of strings. In
addition, `editions` are embedded in the sense that they are a document
containing a year as a 4-character string and the id of a `Publisher` document.
Finally, `lending_status` is a subobject with two fields.

A `Book` instance such as

```json
{
  "title": "The Jungle Book",
  "text": "...",
  "authors_ids": ["60ca4e9734bce5a75816070d"],
  "editions": [
    {"year": "1896", "publisher_id": "60ca4e9734bce5a75816070d", "sales": 1932},
    {"year": "1900", "publisher_id": "60ca4e9734bce5a74816070d", "sales": 1242},
  ],
  "lending_status": {"lent": true, "date": ...}
}
```

would verify and save as long as the specified ids in `authors_ids` and in the
`publisher_id` property of the `editions` items exist in their respective
collections.

As before with `_id`, the field name `authors_ids` implies a virtual getter
`authors` (`await`able) that will dereference all the author documents denoted
by  its ids.

This special syntax only applies if you've defined the type of the field as
`Array`. For the `Array` type, any predicate defined itself as an array applies
to the subdocument in every item. This allows for a lot of
expressiveness.

```js
"editions": [
  Array,  // this field is an array
  "max:2" // max 2 items in length
  [{
    // every item must have
    "year": [String, "length:4"], // a year field (string of length 4)
    "publisher_id": Publisher,    // the id of a Publisher document
  }]
]
```

!!! Note ""
    Nothing stops you from doing crazy things like splitting your definition of
    the subdocument or creating two conflicting definitions, which will cause
    your documents never to verify.
    ```js
    "editions": [
      Array, // this field is an array
      // every array item must be an object
      // 1 with a year field (string of length 4)
      [{"year": [String, "length:4"]}],
      // 2 but also a publisher_id field (with the id of a Publisher)
      [{"publisher_id": Publisher}],
      // 3 but at the same time be a String, wait, what?
      [String],
    ]
    ```
    Obviously, no `Book` instance can satisfy predicates 1 and 2 and predicate 3 
    at the same time, and thus such a definition is useless.


However, the last warning doesn't have much to do with subdocuments per se. You
can easily define scalar fields that never verify either.

```js
import {Domain} from "primate";

export default class NoOne extends Domain {
  static get fields() {
    return {
      "name": [String, "min:10", "max:9"], // will never verify
    };
  };
}
```

## Semantics of predicates

Predicates are always defined respective to a type, and can thus have a
different meaning depending on the type used. Some predicates like `unique`
always have the same meaning regardless of the type: *verify that, all other
things being equal, this field has this exact value only once in the
collection*. Other predicates, like `length`, mean different things with
different types. For a `String`, its length (the number of characters in it),
for an `Array`, the number of items in the array. Not all predicates are defined
for all types: `length` has no meaning in the context of a `Number`. Generally,
predicates try to follow ES semantics if applicable, but in doubt [consult the
documentation][predicates].

!!! note
    If you try to use a predicate that doesn't exist, Primate will throw an
    error at runtime.

## Optional fields

When you define a field, Primate assumes you want it to carry a meaningful value
and will expect its value to be different from `undefined` and `null`. If you
want to relax this, you can add a question mark (`?`) before the field's name to
indicate that it is optional: that is, its predicates will only be checked if it
contains a value different from `undefined` and `null` during verification.
Consider the following example.

```js title="data/domains/Publisher.js"
import {Domain} from "primate";

export default class Publisher extends Domain {
  static get fields() {
    return {
      "name": [String, "unique"],
      "?country": String,
    };
  };
}
```

And based on it, a few `Publisher` documents and their verification results.

```js
console.log(await Publisher.count());
-> 0
// starting with an empty store

// errors: {}
await new Publisher({"name": "Random House"}).save();

// errors: {}
await new Publisher({"name": "Penguin Books", "country": "UK"}).save();

// errors: {"country": "Must be a string"}
await new Publisher({"name": "Numeria Publisher", "country": 44}).save();

// errors: {"name": "Must be unique"})
await new Publisher({"name": "Penguin Books", "country": "US"}).save();
```

!!! note ""
    Trying to define a field twice, once as required and once as optional, will
    result in an error on start up. The same goes for
    [defining a field programmatically](#programmatic-fields), as we will later
    see.

## Transient fields

Sometimes there arises a need to verify data but not save it to a store. A
classical example are passwords. If you need to sign in users, you will probably
need to check their passwords, but you're definitely not interested in storing
plaintext passwords in your store. When you want to verify data but save
only a part of it, transient fields come in handy. To declare a field as
transient, prefix it with a tilde (`~`) as in the following example.

```js title="data/domains/Signin.js"
import {Domain} from "primate";

export default class Signin extends Domain {
  static get collection() {
    return "user";
  }

  static get fields() {
    return {
      "email": [String, "exists"],
      "~password": [String, "compare_encrypted"],
    };
  };
}
```

For that example, assume that the predicates `email_exists` and
`password_correct` are defined. We will get to [custom
predicates](#custom-predicates) later on. In
the `Signin` domain, we are fascading the `user` collection by overriding the
getter
`Domain.collection`, allowing us to perform checks against the same
collection from different angles.

!!! note ""
    We could also just write `class User` to facade `user` instead of overriding
    `Domain.collection`, but it makes more sense to keep it explicit when we're
    using a collection name that's different from the class name. In the same
    vein, while you don't have to specify a class name for a domain that already
    has its `Domain.collection` overwritten, it does align better with all other
    domains and makes the distinction between domain and collection in those
    cases clearer.

!!! note ""
    You can combine optional and transient fields in either order (`~?` or
    `?~`).

## Value coercion

As you work with values and inputs, you will realize that all HTML inputs are
strings, as HTML has no concept of types. That means that if you have an input
field that is linked to a collection field of type `Number`, and Primate were
strict, it would never be able to verify the input, even if you entered
something that is a number like `9` (it would be sent over to the backend as
`"9"` and thus not pass verification). For that reason Primate tries to
coerce a string value into the expected value. It looks into the value of the
string and sees if it logically corresponds to the expected type. Here are a few
examples of  a `String` to `Number` coercion.

```
"999"   -> 999   -> verifies
"999."  -> 999   -> verifies
".999"  -> 0.999 -> verifies
""      -> ?     -> doesn't verify
"0"     -> 0     -> verifies
"0.125" -> 0.125 -> verifies
"0,125" -> ?     -> doesn't verify
```

In other words, a string to number coercion expects the string to contain a numeric value. The same
fundamental principle also works for `String` to `Boolean`.

```
"true"  -> true   -> verifies
"false" -> false  -> verifies
```

Any other strings, regardless of how they evaluate in a boolean context in ES,
won't verify in Primate.

!!! note ""
    Only strings are coerced and coercion currently only takes place to two
    primitives, `number` and `boolean`. There is no coercion to custom types or
    non-scalar types like `array` or `object`.

!!! note ""
    In case you want to take care of coercion yourself, you can use an
    in-function to intercept the value before it gets coerced.

See also the [full documentation of coercion rules][coercion-rules].

## Verification errors

When you verify a document and some fields do not pass verification, Primate
will also tell you the reason. Consider again the following field.

```js
"publishing_year": [String, "length:4", "unique"]
```

Let's see what happens if we try to verify a document with it.

```js
const book = new Book({"publishing year": 1995});
await book.verify();
console.log(book.errors);
-> {"publishing_year": "Must be a string"}
```

We'll fix that by using a string instead of a number.

```js
book.publishing_year = "100";
await book.verify();
console.log(book.errors);
-> {"publishing_year": "Must be 4 characters in length"}
```

Almost there, now we just need a 4-character string.

```js
book.year = "1000";
await book.verify();
console.log(book.errors);
-> {}
await book.save();
```

That worked, no errors are reported. But what if another document had the same
value for this field?

```js
const book2 = new Book({"publishing_year": 1995});
await book2.verify();
console.log(book2.errors);
-> {"publishing_year": "Must be unique"}
```

## Custom predicates

Sometimes you want to define custom verification predicates in addition to the
built-in ones. Custom predicates in Primate are just prototype functions with
a special signature. Let's go back to our `Signin` domain from earlier.

```js title="data/domains/Signin.js"
import {Domain, PredicateError} from "primate";

export default class Signin extends Domain {
  static get collection() {
    return "user";
  }

  static get fields() {
    return {
      "email": [String, "exists"],
      "~password": [String, "compare_encrypted"],
    };
  };

  async exists(property) {
    if (!await this.Class().exists({[property]: this[property]})) {
      throw new PredicateError(`No user exists with this ${property}`);
    }
  }

  async compare_encrypted(property) {
    const encrypted = await encrypt(this[property]);
    const email = this.email;
    if (!await this.Class().exists({email, [property]: encrypted})) {
      throw new PredicateError(`Wrong ${property}");
    }
  }
}
```

Assume for that example that the function `encrypt` is defined and encrypts
plaintext passwords using an algorithm of your choice. The two predicates we
define check, respectively, that a user exists with the given property and that
the encryption of the given property is correct, and otherwise throw.

Predicates are general functions that aren't rigged to any particular field. You
can therefore reuse them with any field and inherit them from a parent class.
However, as the `compare_encrypted` example shows, sometimes they only make
sense for a particular field. We recommend writing them as generic as possible.

!!! note ""
    Custom predicates aren't bound to a type.

!!! note "Throwing `PredicateError`"
    It is important to throw a `PredicateError` and not just an `Error`, as only
    `PredicateError` objects' messages are transported to the front-end as part
    of validation. If you just throw an `Error` object, Primate will take this
    to be a standard error in the application and handle it accordingly.

## Read-only domains
Some domains may serve as a read-only facade for a collection. In these cases
you're not interested in using the domain for saving any data. This might be
true for a domain that is a used for a login form. To indicate that a domain
shouldn't save any data, set its `readonly` getter to `true`.

```js title="data/domains/Signin.js"
import {Domain, PredicateError} from "primate";

export default class Signin extends Domain {
  static get readonly() {
    return true;
  }
}
```

!!! note ""
    The only thing `Domain.readonly` does is prevent `Domain.prototype.save`
    from saving. Verification will still work as expected.

## General-purpose domains
So far we have treated domains as facades for a store collection. But not all
domains have to inherit from `Domain`. In a broader sense, a domain in Primate
is any class that deals with data, regardless if it is stored.

In that vein a domain doesn't have to store information or facade a collection.
For instance, you can create classes within the `data/domains` folder that are
true blackboxes. They only receive input and produce output and you can use them
in different actions in your application. Your domain class doesn't have to
extend `Domain` for that. All you need to do is place your class in the
`data/domains` folder and it will be available to all actions as part of the
`domains` export.

Here is an example for a domain that facades the main operations of the
`jsonwebtoken` package.

```js title="data/domains/JWT.js"
import jwt from "jsonwebtoken";

// This is just for illustration, don't hard-core secrets
const secret = "some-random-secret";

export default class JWT {
  static sign(payload, options = {}) {
    // set default to 60 minutes
    options.expiresIn = options.expiresIn ?? "60m";
    return jwt.sign(payload, secret, options);
  }

  static verify(token) {
    return jwt.verify(token, secret);
  }
}
```

!!! note ""
    Don't store secrets or other sensitive data directly in code. Import it
    from a configuration file or an environment variable during deployment.

## Loose domains

The `Domain` class doesn't depend on a running Primate app. It only requires
a valid `Store` to save its data.

The consequence of this is that you can embed domains within programs that
are not necessarily meant as web applications.

Say that you want to model a cent

## Multi-store domains

!!! note ""
    This is an advanced concept which we recommend skipping if you're new to
    Primate.

[mongodb-store]: https://adaptivecloud.dev/primate/primate-mongodb-store
[file-store]: https://adaptivecloud.dev/primate/primate-file-store
[memory-store]: https://adaptivecloud.dev/primate/primate-memory-store
[stick]: https://adaptivecloud.dev/primate/stick
[defaults]: /guide/setup/configuring#defaults
[views]: /guide/application/views
[predicates]: /guide/data/predicates
[coercion-rules]: /guide/data/predicates#coercion-rules
[builtin-predicates]: /guide/data/predicates#builtin
[dealing-with-ids]: #dealing-with-ids
[ad-hoc-getters]: #ad-hoc-getters

*[ES]: ECMAScript
