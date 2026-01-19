{
  description = "A collection of flake templates for quick project setup";

  outputs = { self }: {
    templates = {
      python-ai-starter = {
        path = ./python-ai-starter;
        description = "Python project template for AI/ML development with uv, ruff, and pre-configured AI SDKs";
      };

      scala-sbt-starter = {
        path = ./scala-sbt-starter;
        description = "Scala project template with sbt, scala-cli, and scalafmt (supports Scala 2.13 and Scala 3)";
      };
    };
  };
}
