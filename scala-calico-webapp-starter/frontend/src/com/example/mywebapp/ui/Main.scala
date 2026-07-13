package com.example.mywebapp.ui

import calico.html.io.{*, given}
import calico.syntax.*
import calico.unsafe.given
import cats.effect.IO
import cats.effect.Resource
import cats.syntax.all.*
import com.example.mywebapp.domain.*
import fs2.concurrent.SignallingRef
import fs2.dom.HtmlElement
import io.circe.parser.decode
import io.circe.syntax.*
import org.scalajs.dom

import scala.scalajs.js

/** Mounts Calico islands into every server-rendered element carrying a
  * data-island attribute.
  */
object Main:

  def main(args: Array[String]): Unit =
    program.useForever.unsafeRunAndForget()

  private def program: Resource[IO, Unit] =
    Resource
      .eval(IO {
        val nodes = dom.document.querySelectorAll("[data-island]")
        (0 until nodes.length).toList
          .map(i => nodes(i).asInstanceOf[dom.HTMLElement])
      })
      .flatMap(_.traverse_(mount))

  private def mount(el: dom.HTMLElement): Resource[IO, Unit] =
    Option(el.getAttribute("data-island")) match
      case Some("note-form") =>
        Resource.eval(IO {
          el.innerHTML = ""
          el.style.minHeight = ""
        }) *> NoteForm().renderInto(el.asInstanceOf[fs2.dom.Node[IO]])
      case _ => Resource.unit

enum FormState:
  case Idle
  case Busy
  case Done(message: String)
  case Failed(message: String)

object NoteForm:

  private val inputCls =
    "w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-slate-900 focus:border-brand focus:outline-none dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100"
  private val labelCls =
    "block mb-1.5 font-medium text-slate-700 dark:text-slate-300"
  private val errorCls = "mt-1 block text-sm text-rose-600"
  private val buttonCls =
    "rounded-lg bg-brand px-5 py-2.5 font-semibold text-white hover:bg-brand-dark disabled:opacity-60"

  private def post(note: NoteRequest): IO[FormState] =
    val request = new dom.RequestInit {}
    request.method = dom.HttpMethod.POST
    request.body = note.asJson.noSpaces
    request.headers = js.Dictionary("Content-Type" -> "application/json")
    IO.fromPromise(IO(dom.fetch("/api/notes", request)))
      .flatMap { response =>
        IO.fromPromise(IO(response.text())).map { text =>
          if response.ok then
            decode[ApiOk](text) match
              case Right(ok) => FormState.Done(ok.message)
              case Left(_)   => FormState.Done("Thanks!")
          else FormState.Failed("Something went wrong. Please try again.")
        }
      }
      .handleError(_ => FormState.Failed("Could not reach the server."))

  def apply(): Resource[IO, HtmlElement[IO]] =
    for
      author <- SignallingRef[IO].of("").toResource
      text <- SignallingRef[IO].of("").toResource
      state <- SignallingRef[IO].of[FormState](FormState.Idle).toResource
      errors <- SignallingRef[IO].of(Map.empty[String, String]).toResource
      el <- render(author, text, state, errors)
    yield el

  private def render(
      author: SignallingRef[IO, String],
      text: SignallingRef[IO, String],
      state: SignallingRef[IO, FormState],
      errors: SignallingRef[IO, Map[String, String]]
  ): Resource[IO, HtmlElement[IO]] =

    def submit: IO[Unit] =
      (author.get, text.get).flatMapN { (a, t) =>
        val note = NoteRequest(a, t)
        val clientErrors = Validation.note(note)
        if clientErrors.nonEmpty then errors.set(clientErrors)
        else
          errors.set(Map.empty) *> state.set(FormState.Busy) *>
            post(note).flatMap(state.set)
      }

    div(
      cls := "space-y-4",
      div(
        cls <-- state.map[List[String]] {
          case FormState.Done(_) =>
            List("rounded-lg bg-emerald-500/10 px-4 py-3 text-emerald-700")
          case FormState.Failed(_) =>
            List("rounded-lg bg-rose-500/10 px-4 py-3 text-rose-700")
          case _ => List("hidden")
        },
        state.map {
          case FormState.Done(m)   => m
          case FormState.Failed(m) => m
          case _                   => ""
        }
      ),
      div(
        label(cls := labelCls, "Your name"),
        input.withSelf { self =>
          (
            cls := inputCls,
            onInput --> (_.foreach(_ => self.value.get.flatMap(author.set)))
          )
        },
        span(cls := errorCls, errors.map(_.getOrElse("author", "")))
      ),
      div(
        label(cls := labelCls, "Note"),
        textArea.withSelf { self =>
          (
            cls := inputCls,
            rows := 3,
            onInput --> (_.foreach(_ => self.value.get.flatMap(text.set)))
          )
        },
        span(cls := errorCls, errors.map(_.getOrElse("text", "")))
      ),
      button(
        `type` := "button",
        cls := buttonCls,
        disabled <-- state.map {
          case FormState.Busy | FormState.Done(_) => true
          case _                                  => false
        },
        onClick --> (_.foreach(_ => submit)),
        state.map {
          case FormState.Busy    => "Sending…"
          case FormState.Done(_) => "Sent ✓"
          case _                 => "Leave a note"
        }
      )
    )
