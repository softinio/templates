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

      scala-mill-library-starter = {
        path = ./scala-mill-library-starter;
        description = "Typelevel-stack Scala library template with Mill, cross-Scala 3 (LTS + latest), cats/cats-effect/FS2, Laika documentation site, and Maven Central publishing";
      };

      scala-calico-webapp-starter = {
        path = ./scala-calico-webapp-starter;
        description = "Full-stack Scala 3 Typelevel webapp template: http4s SSR + Calico (Scala.js) islands, skunk/PostgreSQL, Tailwind, Mill, devshell with postgres, NixOS module";
      };
    };
  };
}
