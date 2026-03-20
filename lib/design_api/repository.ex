defmodule DesignApi.Repository do
  use GenServer

  defmodule User do
    defstruct [:id, :name, :age]
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def create(name, age) when is_binary(name) and is_integer(age) and age >= 0 do
    user = %User{name: name, age: age}
    GenServer.call(__MODULE__, {:create, user})
  end

  def get(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:get, id})
  end

  def update(id, name, age)
      when is_integer(id) and is_binary(name) and is_integer(age) and age >= 0 do
    changes = %{name: name, age: age}
    GenServer.call(__MODULE__, {:update, id, changes})
  end

  def delete(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:delete, id})
  end

  def all() do
    GenServer.call(__MODULE__, :all)
  end

  def count() do
    GenServer.call(__MODULE__, :count)
  end

  def is_exist(id) when is_integer(id) do
    GenServer.call(__MODULE__, {:is_exist, id})
  end

  @impl true
  def handle_call({:create, %User{} = user}, _from, state) do
    id = System.unique_integer([:positive])
    user_with_id = %User{user | id: id}
    new_state = Map.put(state, id, user_with_id)
    {:reply, {:ok, id}, new_state}
  end

  @impl true
  def handle_call({:get, id}, _from, state) do
    {:reply, Map.get(state, id), state}
  end

  @impl true
  def handle_call({:update, id, %{name: name, age: age}}, _from, state) do
    case Map.get(state, id) do
      nil ->
        response = {:error, :not_found}
        {:reply, response, state}

      %User{} = user ->
        updated_user = %User{user | name: name, age: age}
        new_state = Map.put(state, id, updated_user)
        {:reply, :ok, new_state}
    end
  end

  @impl true
  def handle_call({:delete, id}, _from, state) do
    if Map.has_key?(state, id) do
      new_state = Map.delete(state, id)
      {:reply, :ok, new_state}
    else
      error_response = {:error, :not_found}
      {:reply, error_response, state}
    end
  end

  @impl true
  def handle_call(:all, _from, state) do
    {:reply, Map.values(state), state}
  end

  @impl true
  def handle_call(:count, _from, state) do
    {:reply, map_size(state), state}
  end

  @impl true
  def handle_call({:is_exist, id}, _from, state) do
    {:reply, Map.has_key?(state, id), state}
  end
end
