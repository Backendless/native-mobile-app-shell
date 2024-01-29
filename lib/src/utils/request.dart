class Request {
  Request(
    this.operationId,
    this.operationName,
  );

  String operationId;
  String operationName;
  String? userToken;
}
