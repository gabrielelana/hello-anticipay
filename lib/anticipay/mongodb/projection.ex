defmodule Anticipay.MongoDB.Projection do
  defmacro __using__(opts) do
    collection = Keyword.get(opts, :collection)
    indexes = Keyword.get(opts, :indexes, [])
    events = Keyword.get(opts, :events, [])
    default = Keyword.get(opts, :default)
    identity = Keyword.get(opts, :identity)

    quote do
      if unquote(collection) do
        @collection unquote(collection)
      else
        @collection "aggregate.#{Anticipay.MongoDB.collection_name(__MODULE__)}"
      end

      if unquote(default) do
        @default unquote(default)
      else
        @default %{}
      end

      def init do
        Enum.each([%{"_offset" => 1} | unquote(indexes)], &Anticipay.MongoDB.create_index(@collection, &1))
        {:ok, @default, unquote(events)}
      end

      def identity(event) do
        case unquote(identity) do
          nil -> {:error, "Missing `identity` option or `identity` function"}
          field_name when is_binary(field_name) ->
            case Map.get(event, field_name) do
              nil -> {:error, "Event `#{inspect(event)}` is missing field `#{field_name}`"}
              field_value -> {:ok, field_value}
            end
          unexpected ->
            {:error, "Expected a binary as value to `identity` option given `#{inspect(unexpected)}`"}
        end
      end

      def offset do
        # TODO: handle errors
        options = [sort: %{"_offset" => -1}, projection: %{"_offset" => 1, "_id" => 0}, limit: 1]
        case Mongo.find(Anticipay.MongoDB, @collection, %{}, options) |> Enum.to_list do
          [] -> {:ok, -1}
          [%{"_offset" => offset}] -> {:ok, offset}
        end
      end

      def fetch(record_id) do
        # TODO: use internal find and handle errors
        case Mongo.find(Anticipay.MongoDB, @collection, %{"_id" => record_id}) |> Enum.to_list do
          [] -> {:ok, Map.put(@default, "_id", record_id)}
          [d] -> {:ok, Anticipay.MongoDB.from_document(d)}
        end
      end

      def store(record, offset) do
        # TODO: handle errors
        Mongo.save_one(Anticipay.MongoDB, @collection,
          record |> Map.put("_offset", offset) |> Anticipay.MongoDB.to_document)
      end

      def delete(record, offset) do
        # TODO: handle errors
        Mongo.delete_one(Anticipay.MongoDB, @collection, %{"_id" => record["_id"]})
        Mongo.save_one(Anticipay.MongoDB, @collection, %{"_id" => "_offset", "_offset" => offset})
      end

      defoverridable [init: 0, identity: 1, offset: 0, fetch: 1, store: 2, delete: 2]

      def find(query, options \\ []) do
        # TODO: handle errors
        {:ok, Mongo.find(Anticipay.MongoDB, @collection, query, options) |> Enum.to_list}
      end

      def find_one(query, options \\ []) do
        # TODO: handle errors
        case Mongo.find(Anticipay.MongoDB, @collection, query) |> Enum.to_list do
          [d] -> {:ok, d}
          _ -> {:error, :record_not_found}
        end
      end
    end
  end
end
