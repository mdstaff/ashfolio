defmodule Ashfolio.Repo do
  use Ecto.Repo,
    otp_app: :ashfolio,
    adapter: Ecto.Adapters.SQLite3

  def installed_extensions do
    # SQLite doesn't use extensions like PostgreSQL
    []
  end
end
