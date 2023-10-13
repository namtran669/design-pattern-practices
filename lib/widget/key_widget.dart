import 'package:flutter/material.dart';


void main() {
  runApp(ReorderableListApp());
  // runApp(const TextFieldPreservationStateApp());
  // runApp(TextFormApp());


  final map2 = [{"age": 32, "name": "John"}, {"age": 40, "name": "Peter"}, {"age": 24, "name": "Jacky"}];
  int? total = 0;
  map2.forEach((element) {
  });
}


class MyItem {
  final Key key;
  final String title;

  MyItem({required this.key, required this.title});
}

class ReorderableListApp extends StatelessWidget {
  // final List<MyItem> items = [
  //   MyItem(key: UniqueKey(), title: 'Item 1'),
  //   MyItem(key: UniqueKey(), title: 'Item 2'),
  //   MyItem(key: UniqueKey(), title: 'Item 3'),
  // ];

  ReorderableListApp({super.key});

  final List<String> messsage = ['hello','hello','hello','hello', ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Reorderable List Example'),
        ),
        body: ListView.builder(
          itemCount: messsage.length,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, int index) => Row(
            key: UniqueKey(),
            children: [
              Text(messsage[index]),
              const SizedBox(width: 10),
            ],
          ),
          // children: items.map((item) {
          //   return ListTile(
          //     key: item.key,
          //     title: Text(item.title),
          //   );
          // }).toList(),
        ),
      ),
    );
  }
}

class TextFieldPreservationStateApp extends StatelessWidget {
  const TextFieldPreservationStateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyTextFieldWidget(),
    );
  }
}

class MyTextFieldWidget extends StatefulWidget {
  const MyTextFieldWidget({super.key});

  @override
  State createState() => _MyTextFieldWidgetState();
}

class _MyTextFieldWidgetState extends State<MyTextFieldWidget> {
  final GlobalKey<FormFieldState<String>> _textFieldKey =
  GlobalKey<FormFieldState<String>>();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preserve TextField State'),
      ),
      body: Column(
        children: [
          TextFormField(
            key: _textFieldKey,
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Enter Text'),
          ),
          ElevatedButton(
            onPressed: () {
              // _textFieldKey.currentState?.save();
              final enteredText = _controller.text;
              // Do something with enteredText.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Entered Text: $enteredText'),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class TextFormApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _textFieldKey = GlobalKey<FormState>();
  String _inputText = "";

  void _saveText() {
    _textFieldKey.currentState?.save();
    setState(() {
      _inputText = _inputText.trim(); // Loại bỏ dấu cách thừa (nếu có).
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Field Example'),
      ),
      body: Form(
        key: _textFieldKey,
        child: Column(
          children: [
            TextFormField(
              onSaved: (value) {
                _inputText = value ?? "";
              },
            ),
            ElevatedButton(
              onPressed: () {
                _saveText();
              },
              child: const Text('Save Text'),
            ),
            Text('Entered Text: $_inputText'),
          ],
        ),
      ),
    );
  }
}


abstract class A {
  something();
}

mixin B {
  somethingB() {
    print('B');
  }
}

class C extends A with B {
  @override
  something() {
    somethingB();
  }
}
