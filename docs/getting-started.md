---
hide:
  - navigation
---

# Getting started

In this start-up guide we'll create a small but functional blog application.

## Requirements

Primate works on both Node.js and Deno.

### Node.js

Version 17 or later is required. On Arch Linux you can install Node.js by
running

```
pacman -S nodejs
```

If you use another operating system consult its package manager on how to
install Node.js. If your operating system's version of Node.js is too old or
you want more flexibility, use [Node Version Manager][nvm].

### Deno

Version 1.12 or later is required. On Arch Linux you can install Deno by running

```
pacman -S deno
```

If you use another operating system consult its package manager on how to
install Deno.

## Getting up and running

To install Primate create a directory and enter it.
```
mkdir primate-app && cd primate-app
```

Lay out the minimal structure necessary for an application, creating the
directories for your code and SSL files.

```
mkdir -p {domains,stores,routes,components,ssl}
```

Generate your SSL key and certificate.

```
openssl req -x509 -out ssl/default.crt -keyout ssl/default.key -newkey rsa:2048 -nodes -sha256 -batch
```

Create an entry file.

```js title="app.js"
import {app} from "primate";
app.run();
```

### Node

Install Primate from NPM.

```
npm install primate
```

Edit `package.json`, adding a start script and setting the type to `module`.

```json title="package.json"
{
  "scripts": {
    "start": "node --experimental-json-modules app.js"
  },
  "type": "module"
}
```

Start the application.
```
npm start
```

### Deno

Create an `import-map.json` file in the project directory and add
`runtime-compat` and `primate` as dependencies.

```json
{
  "imports": {
    "runtime-compat": "https://deno.land/x/runtime_compat/exports.js",
    "primate": "https://deno.land/x/primate/exports.js"
  }
}
```

Start the application
```
deno run --allow-read --allow-write --allow-net app.js 
```

Congratulations, you have a running Primate application. As it has no data
domains, routes and components, it can't do much yet. Let's flesh it out.

## Adding a store

!!! note
    If you don't care about data persistance, you can skip this section as
    Primate already provides a built-in transient in-memory store as a default.

Start by installing the JSON store module, as it's not part of Primate proper.
```
npm install primate-json-store
```

Create a default store.
```js title="stores/default.js"
import JSONStore from "primate-json-store";
export default new JSONStore({"name": "primate-app", "path": "/tmp"});
```

With this configuration Primate will create `/tmp/primate-app.json` and use it
for all data operations.

??? note "Storage location"
    Linux distributions have different strategies for clearing `/tmp`.
    In doubt, store the data somewhere that you know it won't be automatically
    recycled. It is only important that you don't store it within your
    application structure such that it might be accidentally commited with the
    rest of the code.

??? note "Separation of concerns"
    Ideally you would be splitting the store configuration (the object passed
    to `JSONStore`) from the actual code (importing and instancing the store).
    You could simply not commit `default.js`, or load the configuration from
    another file that's not commited.

## Listing posts

To manage posts in our store, we will need a domain. Domains in Primate are
classes linked to a collection in a store. We'll start by creating a simple
domain that represents posts on our blog.

```js title="domains/Post.js"
import {Domain} from "primate";

export default class Post extends Domain {
  static get fields() {
    return {
      "title": String,
      "text": String,
    };
  }
}
```

A post on our blog should have a title and a text field, both strings.

??? note "Using a different collection"
    `Domain` classes use the lowercase name of the class (in this case
    `post`) to figure out the collection name to use. You can alternatively
    override the static `collection` getter to use a collection name that's
    different from the class name.

Now let's add HTTP routes that allow us to index, view and add/edit posts.
We'll start by creating a route to list all posts.

```js title="routes/post.js"
import {router, html} from "primate";
import Post from "../domains/Post.js";

router.get("/posts", () => html`<post-index posts="${Post.find()}" />`);
```

This route retrieves all posts in the domain `Post` (the collection `post` in
our store) and passes them to the `post-index` component to be rendered as html.
We now only need to add the component itself.

```html title="components/post-index.html"
<h1>All posts</h1>
<div for="${posts}">
  <h2><a href="/post/view/${_id}" value="${title}"></a></h2>
</div>
<h3><a href="/post/edit/">add post</a></h3>
```

This will show a list of all our posts with their title as a link. HTML
components rely on attributes to manipulate the page. A `for` attribute on a
parent tag tells Primate that any attribute within its child tags should be
using the document specified in the `for` attribute. In an attribute you use
template literals syntax to access the properties of a document (as in `href` in
the example above).

!!! note ""
    In case the value used for `for` is an array, Primate duplicates the child
    tags as many times as there are items in the array, wrapping each in a `div`
    tag.

If we had anything in our store, accessing our application now at the address
`/posts` would display a list of posts. Let's go ahead and edit the store's data
file directly (skip this part if you opted out of using `primate-json-store`).

```json title="/tmp/primate-app.json"
{"post": [
  {
    "_id": "1",
    "title": "Writing documentation is a long-winded task",
    "text": "One of the less appreciated parts of software development is..."
  },
  {
    "_id": "2",
    "title": "Revising documentation is an even trickier undertaking",
    "text": "Still haven't got to this part..."
  }
]}
```

Now that we have some data we can finally access the post index page of our
application (pending a restart for the new data to be read in).

## Viewing a post

In addition to viewing the list of all posts we might also want to show
individual posts to our visitors (they are linked to from the index page). For
that, we will add an additional route and component.

=== "Route"
    ```js title="routes/post.js"
    import {router, html, defined} from "primate";
    import Post from "../domains/Post.js";

    router.get("/posts", () => html`<post-index posts="${Post.find()}" />`);

    router.get("/post/view/([a-z0-9]+)", async ({path}) => {
      const [,, _id] = path;
      const post = await Post.one(_id);
      defined(post);
      return html`<post-view post="${post}" />`;
    });
    ```

=== "Component"
    ```html title="components/post-view.html"
    <div for="${post}">
      <h1 value="title"></h1>
      <p value="text"></p>
      <a href="/post/edit/${_id}">edit post</a>
    </div>
    ```

There is not much in the way of new concepts here, except `defined`. The
framework offers you a few invariance methods to safeguard input. One of them is
`defined`, which checks whether an object is defined. If a check fails, Primate
stops executing and redirects you to an error page.

With that we can read existing data from our store and send it to the frontend
for display, either as a list or as an individual post, but what about writing
to the store?

## Adding and editing a post

Next we will create a route that allows us to add a new post or edit an existing
one. Since these two routes are similar in nature they are often implemented
together.

=== "Route"
    ```js title="routes/post.js"
    import {router, html, defined} from "primate";
    import Post from "../domains/Post.js";

    router.get("/posts", () => html`<post-index posts="${Post.find()}" />`);

    router.get("/post/view/([a-z0-9]+)", async ({path}) => {
      const [,, _id] = path;
      defined(_id);
      const post = await Post.one(_id);
      defined(post);
      return html`<post-view post="${post}" />`;
    });

    router.get("/post/edit/([a-z0-9]*)", async ({path}) => {
      const [,, _id] = path;
      // In case we have an id, we're editing, otherwise adding
      const post = _id !== undefined ? await Post.one(_id) : new Post();
      // Make sure that the post exists
      defined(post);
      return html`<post-edit post="${post}" />`;
    });
    ```

=== "Component"
    ```html title="components/post-edit.html"
    <form for="${post}" method="post">
      <h1>Add/edit post</h1>
      <p>
        <input name="title" value="${title}"></textarea>
      </p>
      <p>
        <textarea name="text" value="${text}"></textarea>
      </p>
      <input type="submit" value="Save post" />
    </form>
    ```

This covers both editing and adding a post, but it will only show the form.
Let's add the actual handling part.

=== "Route"
    ```js title="routes/post.js"
    import {router, html, redirect, defined} from "primate";
    import Post from "../domains/Post.js";

    router.get("/posts", () => html`<post-index posts="${Post.find()}" />`);

    router.get("/post/view/([a-z0-9]+)", async ({path}) => {
      const [,, _id] = path;
      defined(_id);
      const post = await Post.one(_id);
      defined(post);
      return html`<post-view post="${post}" />`;
    });

    router.get("/post/edit/([a-z0-9]*)", async ({path}) => {
      const [,, _id] = path;
      // In case we have an id, we're editing, otherwise adding
      const post = _id !== undefined ? await Post.one(_id) : new Post();
      // Make sure that the post exists
      defined(post);
      return html`<post-edit post="${post}" />`;
    });

    router.post("/post/edit/([a-z0-9]*)", async ({path, payload}) => {
      const [,,_id] = path;
      // In case we have an id, we're editing, otherwise adding
      const post = _id !== undefined ? await Post.one(_id) : new Post();
      // Make sure that the post exists
      defined(post);

      return await post.save(payload)
        ? redirect`/post/view/${post._id}`
        : html`<post-edit post="${post}" />`;
    });
    ```

=== "Component"
    ```html title="components/post-edit.html"
    <form for="${post}" method="post">
      <h1>Add/edit post</h1>
      <p>
        <input name="title" value="${title}"></textarea>
      </p>
      <p>
        <textarea name="text" value="${text}"></textarea>
      </p>
      <input type="submit" value="Save post" />
    </form>
    ```

We can now edit existing and add new posts to our store.

To avoid code duplication between similar routes with different HTTP verbs, you
can use the `router.map` to factor out common code. We can also use an alias
to reuse parts of the URL. 

=== "Route"
    ```js title="routes/post.js"
    import {router, html, redirect, defined} from "primate";
    import Post from "../domains/Post.js";

    router.alias("_id", "([a-z0-9]*)");

    router.get("/posts", () => html`<post-index posts="${Post.find()}" />`);

    router.get("/post/view/_id", async ({path}) => {
      const [,, _id] = path;
      defined(_id);
      const post = await Post.one(_id);
      defined(post);
      return html`<post-view post="${post}" />`;
    });

    router.map("/post/edit/_id", async request => {
      const [,, _id] = request.path;
      // In case we have an id, we're editing, otherwise adding
      const post = _id !== undefined ? await Post.one(_id) : new Post();
      // Make sure that the post exists
      defined(post);
      return {...request, post};
    });

    router.get("/post/edit/_id", ({post}) =>
      html`<post-edit post="${post}" />`);

    router.post("/post/edit/_id", async ({post, payload}) =>
      await post.save(payload)
        ? redirect`/post/view/${post._id}`
        : html`<post-edit post="${post}" />`);
    ```

=== "Component"
    ```html title="components/post-edit.html"
    <form for="${post}" method="post">
      <h1>Add/edit post</h1>
      <p>
        <input name="title" value="${title}"></textarea>
      </p>
      <p>
        <textarea name="text" value="${text}"></textarea>
      </p>
      <input type="submit" value="Save post" />
    </form>
    ```

## Verifying data

Verification in Primate happens automatically based on the types and potentially
further predicates you define in `Domain.fields`. Let's say we want to limit the
maximal number of characters to 80 in our posts' `title` field and to 400 in
`text`. We also want to make sure post titles are unique across the collection.

```js title="domains/Post.js"
import {Domain} from "primate";

export default class Post extends Domain {
  static get fields() {
    return {
      "title": [String, "max:80", "unique"],
      "text": [String, "max:400"],
    };
  }
}
```

Instead of using the `String` class to indicate that `title` should only contain
string values, we specify an array that has `String` as its first value and
further predicates as function names, optionally with parameters. We can then
use auto-generated `post.errors` properties to show error messages in our
component.

```html title="components/post-edit.html"
<form for="${post}" method="post">
  <h1>Add/edit post</h1>
  <p>
    <input name="title" value="${title}"></textarea>
    <div value="${errors.title}"></div>
  </p>
  <p>
    <textarea name="text" value="${text}"></textarea>
    <div value="${errors.text}"></div>
  </p>
  <input type="submit" value="Save post" />
</form>
```

Now when you try to hit `Save post` with empty `title` and `text` inputs,
it should display `Must not be empty` below the respective input. Play around
with the different predicates to see what error messages they produce.

## Deleting a post

To complete our CRUD cycle we will add a way to delete a post. As this
request will be initiated from a post's page and redirect to the list of posts
after deletion, it doesn't need its own component. We only modify the post's
view component to show a delete button.

=== "Route"
    ```js title="routes/post.js"
    import {router, defined, html, redirect} from "primate";
    import Post from "../domains/Post.js";

    router.alias("_id", "(?<_id>[a-z0-9]*)");

    router.get("/posts", () => html`<post-index posts="${Post.find()}" />`);

    router.get("/post/view/_id", async ({path}) => {
      const [,, _id] = path;
      defined(_id);
      const post = await Post.one(_id);
      defined(post);
      return html`<post-view post="${post}" />`;
    });

    router.map("/post/edit/_id", async request => {
      const [,, _id] = request.path;
      // In case we have an id, we're editing, otherwise adding
      const post = _id !== undefined ? await Post.one(_id) : new Post();
      // Make sure that the post exists
      defined(post);
      return {...request, post};
    });

    router.get("/post/edit/_id", ({post}) =>
      html`<post-edit post="${post}" />`);

    router.post("/post/edit/_id", async ({post, payload}) =>
      await post.save(payload)
        ? redirect`/post/view/${post._id}`
        : html`<post-edit post="${post}" />`);

    router.post("/post/delete/_id", async ({path}) => {
      const [,, _id] = path;
      defined(_id);
      const post = await Post.one(_id);
      defined(post);

      await post.delete();
      return redirect`/posts`;
    });
    ```

=== "Component"
    ```html title="components/post-view.html"
    <div for="${post}">
      <h1 value="${title}"></h1>
      <p value="${text}"></p>
      <a href="/post/edit/${_id}">Edit post</a>
      <form action="/post/delete/${_id}" method="post">
        <input type="submit" value="Delete post" />
      </form>
    </div>
    ```

With that we have created a basic blogging application that allows us to add,
edit, view and delete posts. We will now move on to mixing information from
different domains.

## Adding comments

To illustrate relationships between Domains we will add a `Comment` Domain. In
our blog a post can have any number of comments (including none), and a comment
must belong to exactly one post. This is a one-to-many (`1:n`) relationship, and
one way to model it is to keep a reference on the `n` side, storing the `_id` of
a comment's post in the `Comment` class. We will also modify our `Post` domain
to retrieve its list of comments.

=== "Comment"
    ```js title="domains/Comment.js"
    import {Domain} from "primate";
    import Post from "./Post.js";

    export default class Comment extends Domain {
      static get fields() {
        return {
          "text": String,
          "post_id": Post,
        };
      }
    }
    ```

=== "Post"
    ```js title="domains/Post.js"
    import {Domain} from "primate";
    import Comment from "./Comment.js";

    export default class Post extends Domain {
      static get fields() {
        return {
          "title": String,
          "text": String,
        };
      }

      get comments() {
        return Comment.find({"post_id": this._id});
      }
    }
    ```

There are a few novelties here. First we can see that we can use `Domain`
classes as types for fields. For such fields Primate will verify that the
*foreign_domain_id* field contains the id of an existing document in the
specified *ForeignDomain*. In case of the `post_id` field of `Comment`, we've
designated it to only accept ids of documents from the `post` collection.

Next you will find an additional getter `comments` in `Post`. As Primate
domains are normal ES classes, you can define getters in them that work as
expected. That is the `comments` getter will return all comments that belong to
a post.

Now that we have the `Comment` domain defined, we can create a route to
comment on posts.

=== "Route"
    ```js title="route/comment.js"
    import {router, defined, html, redirect} from "primate";
    import Comment from "../domains/Comment.js";

    router.map("/comment/add", request => {
      const {post_id} = request.params;
      defined(post_id);
      const comment = new Comment({post_id});
      return {...request, comment};
    });

    router.get("/comment/add", ({comment}) =>
      html`<comment-add comment="${comment}" />`);

    router.post("/comment/add", async ({comment, payload}) =>
      await comment.save(payload)
        ? redirect`/post/view/${comment.post_id}`
        : html`<comment-add comment="${comment}" />`);
    ```

=== "Comment add component"
    ```html title="components/comment-add.html"
    <form for="${comment}" method="post">
      <h1>
        <span>Comment on </span>
        <span value="${post.title}"></span>
      </h1>
      <p>
        <textarea name="text" value="${text}"></textarea>
        <div value="${errors.text}"></div>
      </p>
      <input type="submit" value="Submit comment" />
    </form>
    ```

=== "Post view component"
    ```html title="components/post-view.html"
    <div for="${post}">
      <h1 value="${title}"></h1>
      <p value="${text}"></p>
      <a href="/post/edit/${_id}">Edit post</a>
      <h2>Comments</h2>
      <div for="${comments}">
        <p value="${text}"></p>
      </div>
      <a href="/comment/add?post_id=${_id}">Add comment</a>
      <form action="/post/delete/${_id}" method="post">
        <input type="submit" value="Delete post" />
      </form>
    </div>
    ```

You might be wondering what `post.title` in the example above means. This
is something Primate takes care of automatically for you. Since we defined the
field `post_id` in the `Comment` domain to be of type `Post`, Primate created
a virtual `post` getter within `Comment` that dereferences the post. And in the
component, we can directly access the post's properties with any subproperties.

This is one of the central ideas in Primate: the ability to link domains and
pull in information even without explicitly defining properties, but through
implicit field definitions and use in components.

## Follow-up

The last example rounds up our little blog. We can create, edit, view and delete
posts, and we can comment on posts. But this is only a bit of what is possible
with Primate, and will soon post a general guide. Until then, feel free to
explore by yourself.

*[ES]: ECMAScript
*[CRUD]: Create, read, update, delete
[nvm]: https://github.com/nvm-sh/nvm
[primate-app]: https://github.com/primatejs/primate-app
