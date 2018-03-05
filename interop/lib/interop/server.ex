defmodule Interop.Server do
  @moduledoc false
  use GRPC.Server, service: Grpc.Testing.TestService.Service

  def empty_call(_, _stream) do
    Grpc.Testing.Empty.new()
  end

  def unary_call(req, _) do
    payload = Grpc.Testing.Payload.new(body: String.duplicate("0", req.response_size))
    Grpc.Testing.SimpleResponse.new(payload: payload)
  end

  def streaming_input_call(req_enum, _stream) do
    size = Enum.reduce(req_enum, 0, fn(req, acc) -> acc + byte_size(req.payload.body) end)
    Grpc.Testing.StreamingInputCallResponse.new(aggregated_payload_size: size)
  end

  def streaming_output_call(req, stream) do
    req.response_parameters
    |> Enum.map(&Grpc.Testing.Payload.new(body: String.duplicate("0", &1.size)))
    |> Enum.map(&Grpc.Testing.StreamingOutputCallResponse.new(payload: &1))
    |> Enum.each(&GRPC.Server.stream_send(stream, &1))
  end

  def full_duplex_call(req_enum, stream) do
    Enum.each(req_enum, fn(req) ->
      size = List.first(req.response_parameters).size
      payload = Grpc.Testing.Payload.new(body: String.duplicate("0", size))
      res = Grpc.Testing.StreamingOutputCallResponse.new(payload: payload)
      GRPC.Server.stream_send(stream, res)
    end)
  end
end
