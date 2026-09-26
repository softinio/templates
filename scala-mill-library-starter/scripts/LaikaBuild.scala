//> using scala 3.8.4
//> using dep org.typelevel::laika-core:1.3.2
//> using dep org.typelevel::laika-io:1.3.2

import laika.api.*
import laika.format.*
import laika.io.api.*
import laika.io.syntax.*
import laika.theme.*
import cats.effect.*
import laika.ast.Path.Root
import laika.helium.Helium
import laika.helium.config.*
import java.nio.file.{Files, Paths}
import java.util.Comparator

/** Renders `docs/` into `site/target/docs/site`.
  *
  * This is the *only* place the site is rendered: `mill docs.preview` serves
  * this script's output rather than re-rendering with its own transformer.
  */
object LaikaBuild extends IOApp.Simple {

  /** The release the site documents, substituted for `@VERSION@` in the pages.
    *
    * `mill docs.build` passes it in: from the release tag in CI, or the
    * git-derived version locally. Run on its own, the script falls back to a
    * placeholder.
    */
  val version: String = sys.env.getOrElse("MYLIBRARY_DOC_VERSION", "<version>")

  /** `docs/` with `@VERSION@` replaced, which is what Laika actually renders.
    *
    * Laika's own `${...}` substitution cannot do this: versions appear in
    * dependency lines inside fenced Scala blocks, and the syntax highlighter
    * claims `${...}` in a string literal as Scala interpolation before Laika
    * resolves it, so the variable reaches the page verbatim.
    */
  val sources = Paths.get("site/target/docs/src")

  def stageSources: IO[Unit] = IO.blocking {
    val from = Paths.get("docs")
    if Files.exists(sources) then
      Files.walk(sources).sorted(Comparator.reverseOrder()).forEach(Files.delete)
    Files.walk(from).forEach { path =>
      val to = sources.resolve(from.relativize(path))
      if Files.isDirectory(path) then Files.createDirectories(to)
      else Files.writeString(to, Files.readString(path).replace("@VERSION@", version))
    }
  }

  def run: IO[Unit] = for {
    _ <- IO.println(s"Starting Laika documentation build for $version...")

    heliumTheme = Helium.defaults
      .all.metadata(
        title = Some("MyLibrary"),
        language = Some("en")
      )
      .site.topNavigationBar(
        homeLink = IconLink.internal(Root / "index.md", HeliumIcon.home),
        navLinks = Seq(
          IconLink.external("https://github.com/myorg/mylibrary", HeliumIcon.github)
        )
      )
      .site.mainNavigation(depth = 3)
      .site.footer(
        """MyLibrary is a <a href="https://www.scala-lang.org">Scala 3</a> library.
          |Documentation built with <a href="https://typelevel.org/Laika/">Laika</a>.
          |""".stripMargin
      )
      .build

    transformer = Transformer
      .from(Markdown)
      .to(HTML)
      .using(Markdown.GitHubFlavor)
      .parallel[IO]
      .withTheme(heliumTheme)
      .build

    _ <- stageSources
    _ <- IO.println("Running transformation...")
    _ <- transformer.use { t =>
      t.fromDirectory(sources.toString)
        .toDirectory("site/target/docs/site")
        .transform
    }

    _ <- IO.println("Documentation site built successfully!")
  } yield ()
}
