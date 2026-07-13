package com.example.mylibrary.effect

import cats.effect.IO
import munit.CatsEffectSuite

class MyLibraryIOTest extends CatsEffectSuite:
  test("greet"):
    MyLibraryIO
      .greet("world")
      .map: result =>
        assertEquals(result, "Hello, world!")
