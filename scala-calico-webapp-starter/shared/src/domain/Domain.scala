package com.example.mywebapp.domain

import io.circe.Codec

/** A note as posted by the browser island. */
final case class NoteRequest(author: String, text: String)
    derives Codec.AsObject

/** Standard JSON envelope for the public API. */
final case class ApiOk(message: String) derives Codec.AsObject

/** Field-level validation errors keyed by field name. */
final case class ApiErrors(errors: Map[String, String]) derives Codec.AsObject

/** Field validation shared by the browser island (instant feedback) and the
  * server (source of truth).
  */
object Validation:

  def note(r: NoteRequest): Map[String, String] =
    val author =
      if r.author.trim.isEmpty then Map("author" -> "Name is required")
      else if r.author.length > 100 then
        Map("author" -> "Name must be under 100 characters")
      else Map.empty
    val text =
      if r.text.trim.isEmpty then Map("text" -> "Say something!")
      else if r.text.length > 500 then
        Map("text" -> "Notes must be under 500 characters")
      else Map.empty
    author ++ text
