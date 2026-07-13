package com.example.mywebapp.routes

import cats.data.OptionT
import cats.effect.IO
import com.example.mywebapp.db.NoteRepo
import com.example.mywebapp.domain.*
import com.example.mywebapp.html.Pages
import io.circe.syntax.*
import org.http4s.*
import org.http4s.circe.CirceEntityDecoder.*
import org.http4s.circe.CirceEntityEncoder.*
import org.http4s.dsl.io.*
import org.typelevel.ci.CIString
import org.typelevel.log4cats.slf4j.Slf4jFactory

/** Builds text/html responses with the plain string encoder, explicitly: files
  * that import the circe entity encoders would otherwise JSON-quote the whole
  * page.
  */
object Html:
  private val htmlType = headers.`Content-Type`(
    MediaType.text.html,
    Charset.`UTF-8`
  )

  def ok(body: String): IO[Response[IO]] =
    IO.pure(
      Response[IO](Status.Ok)
        .withEntity(body)(using EntityEncoder.stringEncoder)
        .withContentType(htmlType)
    )

  def notFound(body: String): IO[Response[IO]] =
    IO.pure(
      Response[IO](Status.NotFound)
        .withEntity(body)(using EntityEncoder.stringEncoder)
        .withContentType(htmlType)
    )

final class PublicRoutes(notes: NoteRepo):

  private def unprocessable(body: io.circe.Json): IO[Response[IO]] =
    IO.pure(Response[IO](Status.UnprocessableContent).withEntity(body))

  val routes: HttpRoutes[IO] = HttpRoutes.of[IO] {

    case GET -> Root =>
      notes.latest(20).flatMap(ns => Html.ok(Pages.home(ns)))

    case req @ POST -> Root / "api" / "notes" =>
      req.as[NoteRequest].attempt.flatMap {
        case Left(_) =>
          unprocessable(
            ApiErrors(Map("form" -> "Could not read the submission")).asJson
          )
        case Right(note) =>
          val errors = Validation.note(note)
          if errors.nonEmpty then unprocessable(ApiErrors(errors).asJson)
          else
            notes.insert(note.author.trim, note.text.trim) *>
              Ok(ApiOk("Note added — refresh to see it in the list.").asJson)
      }
  }

/** Serves the bundled static assets (CSS, JS) from the classpath, falling back
  * to a local directory during development so `mill -w frontend.fastLinkJS`
  * output is picked up without re-packaging.
  */
final class Assets(devAssetsDir: Option[String]):

  private given org.typelevel.log4cats.LoggerFactory[IO] =
    Slf4jFactory.create[IO]

  private val cacheHeader =
    Header.Raw(CIString("Cache-Control"), "public, max-age=3600")

  val routes: HttpRoutes[IO] = HttpRoutes.of[IO] {
    case req @ GET -> "assets" /: rest =>
      val name = rest.segments.map(_.encoded).mkString("/")
      if name.contains("..") then NotFound()
      else
        val fromDev = devAssetsDir
          .map(dir =>
            StaticFile.fromPath[IO](fs2.io.file.Path(dir) / name, Some(req))
          )
          .getOrElse(OptionT.none[IO, Response[IO]])
        fromDev
          .orElse(
            StaticFile.fromResource[IO](s"/public/assets/$name", Some(req))
          )
          .map(_.putHeaders(cacheHeader))
          .getOrElseF(NotFound())
  }
