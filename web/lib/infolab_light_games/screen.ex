defmodule Screen do
  use GenServer

  alias Phoenix.PubSub

  @dims Application.get_env(:infolab_light_games, Screen)[:dims]

  @blank Matrix.of_dims(elem(@dims, 0), elem(@dims, 1), Pixel.empty())

  def dims do
    @dims
  end

  def centre_pos do
    {x, y} = @dims

    {Integer.floor_div(x, 2), Integer.floor_div(y, 2)}
  end

  def blank do
    @blank
  end

  @impl true
  def init(_opts) do
    {:ok, @blank}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, @dims, name: __MODULE__)
  end

  def update_frame(new_frame) do
    GenServer.cast(__MODULE__, {:update_frame, new_frame})
  end

  def latest do
    GenServer.call(__MODULE__, :latest)
  end

  @impl true
  def handle_call(:latest, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:update_frame, frame}, state) do
    diff = Matrix.diff(state, frame)

    if not Enum.empty?(diff) do
      InfolabLightGamesWeb.Endpoint.broadcast("screen_diff", "diff", %{data: diff})
      PubSub.broadcast(InfolabLightGames.PubSub, "screen:diff", {:screen_diff, diff})
    end

    PubSub.broadcast(InfolabLightGames.PubSub, "screen:full", {:screen_full, frame})
    {:noreply, frame}
  end
end
