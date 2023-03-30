/// The network status of a message.
enum MessageStatus {
  /// The message is waiting for a network response.
  waiting,

  /// The message is being streamed actively from the network.
  streaming,

  /// The message has been completely received, either instantly or after being
  /// streamed.
  done,

  /// The message had an error occur at some point.
  errored,
}
