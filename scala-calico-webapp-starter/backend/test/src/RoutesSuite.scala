package com.example.mywebapp

import java.time.OffsetDateTime
import java.util.UUID

import cats.effect.IO
import cats.effect.Ref
import com.example.mywebapp.db.Note
import com.example.mywebapp.db.NoteRepo
import munit.CatsEffectSuite
import org.http4s.*
import org.http4s.implicits.*

class RoutesSuite extends CatsEffectSuite {

  private val config = AppConfig(
    http = HttpConfig(
      com.comcast.ip4s.Host.fromString("127.0.0.1").get,
      com.comcast.ip4s.Port.fromInt(8080).get
    ),
    db = DbConfig("localhost", 5432, "test", None, "test", None),
    baseUrl = "http://localhost:8080",
    devAssetsDir = None
  )

  /** Ref-backed repository — no database required for route tests. */
  private def inMemoryNotes: IO[NoteRepo] =
    Ref.of[IO, List[Note]](Nil).map { ref =>
      new NoteRepo:
        def latest(limit: Int): IO[List[Note]] = ref.get.map(_.take(limit))
        def insert(author: String, noteText: String): IO[Note] =
          IO(UUID.randomUUID()).flatMap { id =>
            val n = Note(id, author, noteText, OffsetDateTime.now())
            ref.update(n :: _).as(n)
          }
    }

  private def app: IO[(HttpApp[IO], NoteRepo)] =
    inMemoryNotes.map(notes => (Main.httpApp(config, notes), notes))

  test("home page renders") {
    app.flatMap { case (app, _) =>
      app.run(Request[IO](Method.GET, uri"/")).flatMap { resp =>
        assertEquals(resp.status, Status.Ok)
        resp.as[String].map { body =>
          assert(body.startsWith("<!DOCTYPE html>"))
          assert(body.contains("data-island=\"note-form\""))
        }
      }
    }
  }

  test("valid note is stored") {
    app.flatMap { case (app, notes) =>
      val req = Request[IO](Method.POST, uri"/api/notes")
        .withEntity("""{"author":"Ada","text":"Hello"}""")
        .withContentType(headers.`Content-Type`(MediaType.application.json))
      app.run(req).flatMap { resp =>
        assertEquals(resp.status, Status.Ok)
        notes.latest(10).map(ns => assertEquals(ns.map(_.author), List("Ada")))
      }
    }
  }

  test("invalid note returns field errors and stores nothing") {
    app.flatMap { case (app, notes) =>
      val req = Request[IO](Method.POST, uri"/api/notes")
        .withEntity("""{"author":"","text":""}""")
        .withContentType(headers.`Content-Type`(MediaType.application.json))
      app.run(req).flatMap { resp =>
        assertEquals(resp.status, Status.UnprocessableContent)
        notes.latest(10).map(ns => assertEquals(ns, Nil))
      }
    }
  }

  test("unknown paths get the styled 404") {
    app.flatMap { case (app, _) =>
      app.run(Request[IO](Method.GET, uri"/nope")).map { resp =>
        assertEquals(resp.status, Status.NotFound)
      }
    }
  }
}
