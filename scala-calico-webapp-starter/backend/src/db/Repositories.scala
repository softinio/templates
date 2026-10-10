package com.example.mywebapp.db

import cats.effect.IO
import cats.effect.Resource
import skunk.*
import skunk.codec.all.*
import skunk.implicits.*

import java.time.OffsetDateTime
import java.util.UUID

final case class Note(
    id: UUID,
    author: String,
    text: String,
    createdAt: OffsetDateTime
)

trait NoteRepo:
  def latest(limit: Int): IO[List[Note]]
  def insert(author: String, noteText: String): IO[Note]

object NoteRepo:

  private val noteCodec: Codec[Note] =
    (uuid *: text *: text *: timestamptz).to[Note]

  def skunk(sessions: Resource[IO, Session[IO]]): NoteRepo =
    new NoteRepo:
      def latest(limit: Int): IO[List[Note]] =
        sessions.use(
          _.execute(
            sql"""SELECT id, author, body, created_at FROM notes
                  ORDER BY created_at DESC LIMIT $int4""".query(noteCodec)
          )(limit)
        )

      def insert(author: String, noteText: String): IO[Note] =
        sessions.use(
          _.unique(
            sql"""INSERT INTO notes (author, body) VALUES ($text, $text)
                  RETURNING id, author, body, created_at""".query(noteCodec)
          )((author, noteText))
        )
