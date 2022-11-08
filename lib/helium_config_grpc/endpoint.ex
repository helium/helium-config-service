defmodule HeliumConfigGRPC.Endpoint do
  use GRPC.Endpoint

  intercept GRPC.Logger.Server
  run(HeliumConfigGRPC.RouteServer)
  run(HeliumConfigGRPC.OrgServer)
end
