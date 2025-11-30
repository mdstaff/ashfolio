defmodule Ashfolio.Legal do
  @moduledoc """
  Ash domain for legal and compliance resources.

  Contains resources for managing user consent and GDPR compliance
  for AI features in the application.
  """
  use Ash.Domain

  resources do
    resource(Ashfolio.Legal.AiConsent)
    resource(Ashfolio.Legal.ConsentAudit)
  end
end
