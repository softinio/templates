package com.example.mylibrary

class MyLibraryTest extends munit.FunSuite:
  test("greet"):
    assertEquals(MyLibrary.greet("world"), "Hello, world!")
