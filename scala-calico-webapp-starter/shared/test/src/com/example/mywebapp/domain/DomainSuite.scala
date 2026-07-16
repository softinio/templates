package com.example.mywebapp.domain

class DomainSuite extends munit.FunSuite {

  test("validation flags missing fields") {
    val errors = Validation.note(NoteRequest("", ""))
    assertEquals(errors.keySet, Set("author", "text"))
  }

  test("validation passes a good note") {
    assertEquals(
      Validation.note(NoteRequest("Ada", "Hello from the analytical engine")),
      Map.empty[String, String]
    )
  }

  test("codecs round-trip NoteRequest") {
    import io.circe.syntax.*
    val note = NoteRequest("Grace", "COBOL says hi")
    assertEquals(
      io.circe.parser.decode[NoteRequest](note.asJson.noSpaces),
      Right(note)
    )
  }
}
