package com.example.mywebapp.db

import cats.effect.IO
import cats.effect.Resource
import com.example.mywebapp.DbConfig
import dumbo.Dumbo
import dumbo.logging.Implicits.console as dumboConsoleLogger
import org.typelevel.log4cats.Logger
import org.typelevel.otel4s.metrics.Meter
import org.typelevel.otel4s.trace.Tracer
import skunk.Session

object Database:

  private given Tracer[IO] = Tracer.noop[IO]
  private given Meter[IO] = Meter.noop[IO]

  def pool(config: DbConfig): Resource[IO, Resource[IO, Session[IO]]] =
    val base = Session
      .Builder[IO]
      .withDatabase(config.database)
    val withConn = config.unixSocketDir match
      case Some(dir) => base.withUnixSocketDirectory(dir)
      case None      => base.withHost(config.host).withPort(config.port)
    val withAuth = config.password match
      case Some(pw) => withConn.withUserAndPassword(config.user, pw)
      case None     => withConn.withUser(config.user)
    withAuth.pooled(max = 10)

  // NOTE: every new migration file must also be added to this list
  def migrate(sessions: Resource[IO, Session[IO]])(using
      Logger[IO]
  ): IO[Unit] =
    Dumbo
      .withResources[IO](
        List(
          dumbo.ResourceFilePath("/db/migration/V1__init.sql")
        )
      )
      .withSession(sessions)(using cats.effect.Sync[IO], dumboConsoleLogger)
      .runMigration
      .flatMap { result =>
        Logger[IO].info(
          s"Database migrations applied: ${result.migrationsExecuted}"
        )
      }
