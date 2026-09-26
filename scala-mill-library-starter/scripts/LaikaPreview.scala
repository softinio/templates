//> using scala 3.8.4
//> using dep org.http4s::http4s-ember-server:0.23.36
//> using dep org.http4s::http4s-dsl:0.23.36

import cats.effect.*
import com.comcast.ip4s.*
import java.nio.file.Paths
import org.http4s.*
import org.http4s.dsl.io.*
import org.http4s.ember.server.EmberServerBuilder

/** Serves the site `mill docs.build` produced, at http://localhost:4242.
  *
  * Deliberately does not render anything itself. A preview that carries its
  * own copy of the Laika transformer drifts from `LaikaBuild.scala` -- theme
  * settings, extensions and the `@VERSION@` substitution all have to be kept in
  * step by hand. Serving the built output means the preview is, by
  * construction, what gets published.
  */
object LaikaPreview extends IOApp.Simple {

  private val siteDir = "site/target/docs/site"

  private val app = HttpRoutes
    .of[IO] { case request @ GET -> path =>
      val raw  = path.toString
      val rel  = if raw == "/" || raw.isEmpty then "/index.html" else raw
      // Serve a directory's index.html, as GitHub Pages does.
      val file = Paths.get(siteDir, rel).toFile match
        case dir if dir.isDirectory => Paths.get(dir.getPath, "index.html").toFile
        case other                  => other
      if file.exists() then StaticFile.fromFile[IO](file, Some(request)).getOrElseF(NotFound())
      else NotFound()
    }
    .orNotFound

  def run: IO[Unit] =
    IO.println("Serving the built site at http://localhost:4242 (Ctrl+C to stop)") *>
      EmberServerBuilder
        .default[IO]
        .withHost(ipv4"0.0.0.0")
        .withPort(port"4242")
        .withHttpApp(app)
        .build
        .useForever
}
