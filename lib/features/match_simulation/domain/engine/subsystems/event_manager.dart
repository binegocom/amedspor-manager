import '../../models/match_event.dart';

class EventManager {
  final List<MatchEvent> matchEvents = [];
  final int maxEvents;

  EventManager({this.maxEvents = 50});

  void addEvent(MatchEvent event) {
    matchEvents.add(event);
    if (matchEvents.length > maxEvents) {
      matchEvents.removeAt(0);
    }
  }

  void clear() {
    matchEvents.clear();
  }
}
