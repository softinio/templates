package com.example.mywebapp.html

import com.example.mywebapp.db.Note
import scalatags.Text.all.*

import java.time.ZoneId
import java.time.format.DateTimeFormatter

object Pages:

  private val dateFmt =
    DateTimeFormatter.ofPattern("MMM d, yyyy h:mm a").withZone(ZoneId.of("UTC"))

  private def shell(pageTitle: String)(content: Frag*): String =
    "<!DOCTYPE html>" + html(
      lang := "en",
      head(
        scalatags.Text.tags2.title(pageTitle),
        tag("meta")(attr("charset") := "utf-8"),
        tag("meta")(
          name := "viewport",
          attr("content") := "width=device-width, initial-scale=1"
        ),
        link(rel := "stylesheet", href := "/assets/app.css"),
        script(src := "/assets/main.js", attr("defer").empty)
      ),
      body(
        cls := "min-h-screen bg-white font-sans text-slate-800 antialiased dark:bg-slate-950 dark:text-slate-200",
        tag("main")(
          cls := "mx-auto max-w-2xl px-4 py-12",
          content
        )
      )
    ).render

  /** Home page: server-rendered list of notes + a Calico island form. The
    * island div carries data-island/data-props attributes; the frontend module
    * mounts the interactive form into it.
    */
  def home(notes: List[Note]): String =
    shell("My Web App")(
      h1(
        cls := "text-4xl font-bold tracking-tight text-slate-900 dark:text-white",
        "My ",
        span(cls := "text-brand", "Web App")
      ),
      p(
        cls := "mt-3 text-slate-600 dark:text-slate-400",
        "A Typelevel-stack starter: http4s server-side rendering, a Calico (Scala.js) island below, skunk + PostgreSQL behind it. Leave a note to see the whole loop work."
      ),
      div(
        cls := "mt-8",
        attr("data-island") := "note-form",
        attr("data-props") := "{}",
        style := "min-height: 12rem"
      ),
      h2(
        cls := "mt-10 text-xl font-bold text-slate-900 dark:text-white",
        "Notes"
      ),
      if notes.isEmpty then
        p(cls := "mt-4 text-slate-500", "No notes yet — be the first!")
      else
        ul(
          cls := "mt-4 space-y-3",
          notes.map(n =>
            li(
              cls := "rounded-lg border border-slate-200 p-4 dark:border-slate-800",
              p(n.text),
              p(
                cls := "mt-1 font-mono text-xs text-slate-500",
                s"— ${n.author}, ${dateFmt.format(n.createdAt)}"
              )
            )
          )
        )
    )

  def notFound: String =
    shell("Not found")(
      h1(cls := "text-2xl font-bold", "404 — page not found"),
      p(cls := "mt-2", a(href := "/", cls := "text-brand underline", "Home"))
    )
