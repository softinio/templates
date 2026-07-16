# MyLibrary

A Scala 3 library.

## Installation

MyLibrary is published to Maven Central for Scala 3. Add it to your build:

### Mill

```scala
def mvnDeps = Seq(
  mvn"com.example::mylibrary:<version>"
)
```

### sbt

```scala
libraryDependencies += "com.example" %% "mylibrary" % "<version>"
```

For the cats-effect integration module, also add `mylibrary-cats-effect`.

## Usage

```scala
import com.example.mylibrary.MyLibrary

MyLibrary.greet("World") // "Hello, World!"
```

With cats-effect:

```scala
import com.example.mylibrary.effect.MyLibraryIO

MyLibraryIO.greet("World") // IO("Hello, World!")
```

## Documentation

This site is built with [Laika](https://typelevel.org/Laika/) from the
Markdown sources in the `docs/` directory. Add more pages by dropping
additional `.md` files next to this one.

- `mill docs.build` — build the site into `site/target/docs/site`
- `mill docs.preview` — build and serve the site at `http://localhost:4242`
