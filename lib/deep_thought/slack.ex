defmodule DeepThought.Slack do
  @moduledoc """
  The Slack context.
  """

  import Ecto.Query, warn: false
  alias DeepThought.Repo
  alias DeepThought.Slack.{Translation, User}

  @doc """
  Find users by user_ids.
  """
  @spec find_users_by_user_ids([String.t()]) :: [User.t()]
  def find_users_by_user_ids(user_ids) do
    User.find_by_user_ids(user_ids)
    |> Repo.all()
  end

  @doc """
  Inserts or updates user information in database.
  """
  @spec update_users!([map()]) :: [User.t()]
  def update_users!(users) do
    users
    |> Stream.map(fn user -> User.changeset(%User{}, user) end)
    |> Enum.reduce([], fn changeset, acc ->
      [
        Repo.insert!(changeset,
          returning: true,
          conflict_target: :user_id,
          on_conflict: {:replace_all_except, [:id, :user_id]}
        )
        | acc
      ]
    end)
    |> Enum.reverse()
  end

  @doc """
  Determines whether message was recently translated into a given language.
  """
  @spec recently_translated?(String.t(), String.t(), String.t()) :: boolean()
  def recently_translated?(channel_id, message_ts, target_language),
    do:
      Translation.recently_translated?(channel_id, message_ts, target_language)
      |> Repo.all()
      |> Enum.count() > 0

  @doc """
  Marks a translation as deleted from the Slack thread.
  """
  @spec mark_as_deleted(String.t(), String.t()) :: Translation.r()
  def mark_as_deleted(channel_id, message_ts) do
    Translation.find_by_translation(channel_id, message_ts)
    |> Repo.one!()
    |> Translation.deletion_changeset(%{status: "deleted"})
    |> Repo.update()
  end

  @doc """
  Creates a translation request record in database.
  """
  @spec create_translation(map()) :: Translation.r()
  def create_translation(attrs \\ %{}) do
    %Translation{}
    |> Translation.changeset(attrs)
    |> Repo.insert()
  end
end
