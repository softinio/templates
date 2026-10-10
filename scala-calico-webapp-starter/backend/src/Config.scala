package com.example.mywebapp

import cats.effect.IO
import cats.syntax.all.*
import ciris.*
import com.comcast.ip4s.Host
import com.comcast.ip4s.Port

final case class HttpConfig(host: Host, port: Port)

final case class DbConfig(
    host: String,
    port: Int,
    user: String,
    password: Option[String],
    database: String,
    // when set (e.g. /run/postgresql on NixOS) connect via unix socket
    unixSocketDir: Option[String]
)

final case class AppConfig(
    http: HttpConfig,
    db: DbConfig,
    baseUrl: String,
    devAssetsDir: Option[String]
)

object AppConfig:

  private given ConfigDecoder[String, Host] =
    ConfigDecoder[String].mapOption("Host")(Host.fromString)

  private val portDecoder: ConfigDecoder[String, Port] =
    ConfigDecoder[String, Int].mapOption("Port")(Port.fromInt)

  val load: IO[AppConfig] =
    val http = (
      env("MYWEBAPP_HTTP_HOST")
        .as[Host]
        .default(Host.fromString("0.0.0.0").get),
      env("MYWEBAPP_HTTP_PORT")
        .as[Port](using portDecoder)
        .default(Port.fromInt(8080).get)
    ).parMapN(HttpConfig.apply)

    val db = (
      env("MYWEBAPP_DB_HOST").default("localhost"),
      env("MYWEBAPP_DB_PORT").as[Int].default(5432),
      env("MYWEBAPP_DB_USER").default("mywebapp"),
      env("MYWEBAPP_DB_PASSWORD").option,
      env("MYWEBAPP_DB_NAME").default("mywebapp"),
      env("MYWEBAPP_DB_SOCKET_DIR").option
    ).parMapN(DbConfig.apply)

    (
      http,
      db,
      env("MYWEBAPP_BASE_URL").default("http://localhost:8080"),
      env("MYWEBAPP_DEV_ASSETS").option
    ).parMapN(AppConfig.apply).load[IO]
