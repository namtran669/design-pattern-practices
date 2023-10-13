import 'package:rxdart/rxdart.dart';
void main() {

  // Subject
  final names = BehaviorSubject<List<String>>();
  final scores = BehaviorSubject<List<int>>();

  final users = Rx.zip2(
    names.stream,
    scores.stream,
        (List<String> nameList, List<int> scoreList) {
      final userList = <User>[];
      for (var i = 0; i < nameList.length; i++) {
        final user = User(nameList[i], scoreList[i]);
        userList.add(user);
      }
      return userList;
    },
  );

  names.add(["Alice", "Bob", "Charlie"]);
  scores.add([85, 92, 78]);

  users.listen((userList) {
    for (final user in userList) {
      print("${user.name}: ${user.score}");
    }
  });
}


class User {
  final String name;
  final int score;

  User(this.name, this.score);
}