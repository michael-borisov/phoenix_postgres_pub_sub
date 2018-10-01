defmodule PhoenixPostgresPubSub do
  use GenServer

  require Logger

  @doc """
  Initialize the GenServer
  """
  @spec start_link(List.t()) :: {:ok, pid}
  def start_link(channels), do: GenServer.start_link(__MODULE__, channels, name: __MODULE__)

  @doc """
  When the GenServer starts subscribe to the given channel
  """
  @spec init(List.t()) :: {:ok, []}
  def init(channels) do
    pg_config = DataBucket.Repo.config()
    {:ok, pid} = Postgrex.Notifications.start_link(pg_config)

    list_of_channels = List.wrap(channels)
    Enum.map(list_of_channels, fn channel -> Postgrex.Notifications.listen(pid, channel) end)

    {:ok, {pid, channels, nil}}
  end

  @doc """
  Listen for changes
  """
  def handle_info(notification, _state) do
    adapter = adapter_from_config()
    apply(adapter, :handle_postgres_notification, [notification])

    {:noreply, :event_handled}
  end

  defp adapter_from_config() do
    Application.fetch_env!(:phoenix_postgres_pubsub, :adapter)
  end
end