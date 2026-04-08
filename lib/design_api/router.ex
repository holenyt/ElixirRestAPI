defmodule DesignApi.Router do
  use Plug.Router

  plug(:match)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason)
  plug(:dispatch)

  post "/users" do
    with {:ok, %{"name" => name, "age" => age}} <- validate_post(conn.body_params),
         {:ok, id} <- DesignApi.Repository.create(name, age) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(201, Jason.encode!(%{id: id}))
    else
      {:error, reason} -> send_json_error(conn, 400, reason)
    end
  end

  get "/users/count" do
    count = DesignApi.Repository.count()
    send_json(conn, 200, %{count: count})
  end

  get "/users" do
    users = DesignApi.Repository.all()
    send_json(conn, 200, users)
  end

  get "/users/:id" do
    case Integer.parse(id) do
      {id_int, ""} ->
        case DesignApi.Repository.get(id_int) do
          nil -> send_json_error(conn, 404, "User not found")
          user -> send_json(conn, 200, user)
        end

      :error ->
        send_json_error(conn, 400, "Invalid ID format")
    end
  end

  put "/users/:id" do
    with {id_, ""} <- Integer.parse(id),
         {:ok, %{"name" => name, "age" => age}} <- validate_put(conn.body_params),
         :ok <- DesignApi.Repository.update(id_, name, age) do
      send_resp(conn, 204, "")
    else
      :error -> send_json_error(conn, 400, "Invalid ID format")
      {:error, :not_found} -> send_json_error(conn, 404, "User not found")
      {:error, reason} -> send_json_error(conn, 400, reason)
    end
  end

  delete "/users/:id" do
    case Integer.parse(id) do
      {id_, ""} ->
        case DesignApi.Repository.delete(id_) do
          :ok -> send_resp(conn, 204, "")
          {:error, :not_found} -> send_json_error(conn, 404, "User not found")
        end

      :error ->
        send_json_error(conn, 400, "Invalid ID format")
    end
  end

  match _ do
    send_json_error(conn, 404, "Not found")
  end

  defp validate_post(%{"name" => name, "age" => age})
       when is_binary(name) and is_integer(age) and age >= 0 do
    {:ok, %{"name" => name, "age" => age}}
  end

  defp validate_post(_),
    do: {:error, "Name should be string and age should be positive integer"}

  defp validate_put(%{"name" => name, "age" => age})
       when is_binary(name) and is_integer(age) and age >= 0 do
    {:ok, %{"name" => name, "age" => age}}
  end

  defp validate_put(_),
    do: {:error, "Name should be string and age should be positive integer"}

  defp send_json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  defp send_json_error(conn, status, message) do
    send_json(conn, status, %{error: message})
  end
end
