package com.example.mywebapp

import cats.data.Kleisli
import cats.effect.IO
import cats.effect.IOApp
import cats.syntax.all.*
import com.example.mywebapp.db.Database
import com.example.mywebapp.db.NoteRepo
import com.example.mywebapp.html.Pages
import com.example.mywebapp.routes.*
import org.http4s.HttpApp
import org.http4s.ember.server.EmberServerBuilder
import org.typelevel.log4cats.Logger
import org.typelevel.log4cats.LoggerFactory
import org.typelevel.log4cats.slf4j.Slf4jFactory
import org.typelevel.log4cats.slf4j.Slf4jLogger

object Main extends IOApp.Simple:

  private given LoggerFactory[IO] = Slf4jFactory.create[IO]

  def httpApp(config: AppConfig, notes: NoteRepo): HttpApp[IO] =
    val public = PublicRoutes(notes)
    val assets = Assets(config.devAssetsDir)
    val routes = assets.routes <+> public.routes
    Kleisli(req => routes.run(req).getOrElseF(Html.notFound(Pages.notFound)))

  def run: IO[Unit] =
    Slf4jLogger.create[IO].flatMap { case given Logger[IO] =>
      AppConfig.load.flatMap { config =>
        val resources =
          for
            sessions <- Database.pool(config.db)
            _ <- cats.effect.Resource.eval(Database.migrate(sessions))
            notes = NoteRepo.skunk(sessions)
            server <- EmberServerBuilder
              .default[IO]
              .withHost(config.http.host)
              .withPort(config.http.port)
              .withHttpApp(httpApp(config, notes))
              .build
          yield server

        resources.use { server =>
          Logger[IO].info(s"mywebapp listening on ${server.address}") *>
            IO.never
        }
      }
    }
