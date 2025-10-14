{
  description = "A collection of flake templates for quick project setup";

  outputs = { self }: {
    templates = {
      python-ai-starter = {
        path = ./python-ai-starter;
        description = "Python project template for AI/ML development with uv, ruff, and pre-configured AI SDKs";
      };
    };
  };
}
