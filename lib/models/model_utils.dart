/// Top level function for deserializing millis from json to [DateTime].
DateTime jsonToDate(int? value) => value != null
    ? DateTime.fromMillisecondsSinceEpoch(value).toLocal()
    : DateTime.now();

/// Top level function for serializing [DateTime] to millisecondsSinceEpoch.
int dateToJson(DateTime date) => date.toUtc().millisecondsSinceEpoch;
