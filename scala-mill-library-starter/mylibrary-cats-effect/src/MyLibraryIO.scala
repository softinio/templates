package com.example.mylibrary.effect

import cats.effect.IO

object MyLibraryIO:
  def greet(name: String): IO[String] = IO(s"Hello, $name!")
