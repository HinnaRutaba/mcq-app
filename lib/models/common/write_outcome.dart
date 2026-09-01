/// The result of a write, carrying what the server said about it.
///
/// **201 means created; 200 means "you already sent that".** A 200 on a
/// create is the server telling you the retry worked and there is nothing
/// new: the UI must not announce "fine imposed" twice, and the offline
/// queue must mark the item done rather than retrying it again.
class WriteOutcome<T> {
  const WriteOutcome({
    required this.value,
    required this.wasCreated,
    this.message,
  });

  final T value;
  final bool wasCreated;

  /// The server's own sentence. Already translated; show it verbatim.
  final String? message;

  bool get wasReplay => !wasCreated;
}
