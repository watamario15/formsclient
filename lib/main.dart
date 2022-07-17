import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';

class Selection {
  final int label;
  final String value;

  const Selection(this.label, this.value);

  Selection.fromJson(Map<String, dynamic> json)
      : label = json['label']!,
        value = json['value']!;

  Map<String, dynamic> toJson() => {'label': label, 'value': value};
}

class Question {
  final int id;
  final String type;
  final String explanation;
  final List<Selection> selections;

  const Question(this.id, this.type, this.explanation, this.selections);

  Question.fromJson(Map<String, dynamic> json)
      : id = json['id']!,
        type = json['type']!,
        explanation = json['explanation']!,
        selections = [
          for (var item in json['selection']!) Selection.fromJson(item)
        ];

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'explanation': explanation,
        'selection': selections
      };
}

class MyFormModel {
  final String id;
  final String title;
  final List<Question> questions;

  const MyFormModel(this.id, this.title, this.questions);

  MyFormModel.fromJson(Map<String, dynamic> json)
      : id = json['id']!,
        title = json['title']!,
        questions = [
          for (var item in json['questions']!) Question.fromJson(item)
        ];

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'questions': questions};
}

class GetFormModel {
  final String result;
  final String id;
  final MyFormModel form;

  const GetFormModel(this.result, this.id, this.form);

  GetFormModel.fromJson(Map<String, dynamic> json)
      : result = json['result']!,
        id = json['id']!,
        form = MyFormModel.fromJson(json['form']!);

  Map<String, dynamic> toJson() => {'result': result, 'id': id, 'form': form};
}

class Answer {
  final int id;
  final String type;
  String? textValue;
  Map<int, bool>? radioValue;

  Answer(this.id, this.type, dynamic value) {
    if (type == 'text') {
      textValue = value;
    } else if (type == 'radio') {
      radioValue = value;
    } else {
      throw Exception("No such type: $type.");
    }
  }

  Answer.fromJson(Map<String, dynamic> json)
      : id = json['id']!,
        type = json['type']! {
    if (type == 'text') {
      textValue = json['value']!;
    } else if (type == 'radio') {
      radioValue = json['value']!;
    } else {
      throw Exception("No such type: $type.");
    }
  }

  Map<String, dynamic> toJson() =>
      {'id': id, 'type': type, 'value': textValue ?? radioValue};
}

class AnswerModel {
  final String id;
  final List<Answer> answers;

  const AnswerModel(this.id, this.answers);

  AnswerModel.fromJson(Map<String, dynamic> json)
      : id = json['id']!,
        answers = [for (var item in json['answers']!) Answer.fromJson(item)];

  Map<String, dynamic> toJson() => {'id': id, 'answers': answers};
}

class AnswerResponse {
  final String result;
  final String? id;
  final String message;

  const AnswerResponse(this.result, this.id, this.message);

  AnswerResponse.fromJson(Map<String, dynamic> json)
      : result = json['result']!,
        id = json['id'],
        message = json['message']!;

  Map<String, dynamic> toJson() =>
      {'result': result, if (id != null) 'id': id, 'message': message};
}

class CheckboxFormField extends FormField<Map<int, bool>> {
  CheckboxFormField({
    Key? key,
    FormFieldSetter<Map<int, bool>>? onSaved,
    FormFieldValidator<Map<int, bool>>? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    Map<int, bool>? initialValue,
    required List<Selection> options,
  }) : super(
          key: key,
          onSaved: onSaved,
          validator: validator,
          initialValue: initialValue ?? {},
          autovalidateMode: autovalidateMode,
          builder: (state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var item in options)
                  CheckboxListTile(
                    title: Text(item.value),
                    value: state.value!.putIfAbsent(item.label, () => false),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (flag) {
                      if (flag == null) return;
                      final newState = state.value!;
                      newState[item.label] = flag;
                      state.didChange(newState);
                    },
                  ),
              ],
            );
          },
        );
}

String? hostName, formID;

class MyForm extends StatefulWidget {
  const MyForm({Key? key}) : super(key: key);

  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();
  Future<GetFormModel>? _futureForm;

  /*
  final _formResponse = const GetFormModel(
    'ok',
    'someid',
    MyFormModel(
      'testform',
      [
        Question(
          0,
          'radio',
          'Hey! This is radio!',
          [
            Selection(0, 'This is first'),
            Selection(1, 'This is second'),
            Selection(2, 'This is third'),
          ],
        ),
        Question(1, 'text', 'Hey! This is text!', []),
      ],
    ),
  );
  */

  Future<GetFormModel> fetchForm(String host, String id) async {
    final response =
        await http.get(Uri.parse('http://$host:8080/get-form/$id'));

    if (response.statusCode == 200) {
      return GetFormModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch form "$id" from $host.');
    }
  }

  /// タイトル
  Widget _title(String title) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headline3,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.resolveWith(
                          (states) => states.contains(MaterialState.disabled)
                              ? null
                              : Colors.white),
                      backgroundColor: MaterialStateProperty.resolveWith(
                          (states) => states.contains(MaterialState.disabled)
                              ? null
                              : Colors.blue),
                    ),
                    onPressed: null, // 未実装
                    child: const Text('Modify this form'),
                  ),
                  TextButton(
                    style: ButtonStyle(
                      foregroundColor: MaterialStateProperty.resolveWith(
                          (states) => states.contains(MaterialState.disabled)
                              ? null
                              : Colors.white),
                      backgroundColor: MaterialStateProperty.resolveWith(
                          (states) => states.contains(MaterialState.disabled)
                              ? null
                              : Colors.blue),
                    ),
                    onPressed: null, // 未実装
                    child: const Text('Show answers'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  /// 質問項目
  Widget _formItem(Question question) => Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  question.explanation,
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
              question.type == 'text'
                  ? TextFormField(
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onSaved: (content) {},
                    )
                  : CheckboxFormField(
                      options: question.selections,
                      onSaved: (selected) {},
                    ),
            ],
          ),
        ),
      );

  @override
  void initState() {
    super.initState();
    _futureForm = fetchForm(hostName!, formID!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Zemi-A Forms'),
      ),
      body: FutureBuilder<GetFormModel>(
        future: _futureForm,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  _title(snapshot.data!.form.title),
                  for (var item in snapshot.data!.form.questions)
                    _formItem(item),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: SizedBox(
                width: 400,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Failed to fetch a form. '
                      'Please make sure you entered a server and an ID correctly.\n\n'
                      'Error: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _formKey.currentState!.save(),
        tooltip: 'Submit',
        child: const Icon(Icons.send),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: Card(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Sign in',
                        style: Theme.of(context).textTheme.headline4),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      decoration:
                          const InputDecoration(hintText: 'Form server'),
                      onSaved: (value) {
                        hostName = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a form server name.';
                        }
                        return null;
                      },
                      autofocus: true,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextFormField(
                      decoration: const InputDecoration(hintText: 'Form ID'),
                      onSaved: (value) {
                        formID = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an form ID.';
                        }
                        return null;
                      },
                      onFieldSubmitted: (value) {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          Navigator.of(context).pushNamed('/answer');
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextButton(
                      style: ButtonStyle(
                        foregroundColor: MaterialStateProperty.resolveWith(
                            (states) => states.contains(MaterialState.disabled)
                                ? null
                                : Colors.white),
                        backgroundColor: MaterialStateProperty.resolveWith(
                            (states) => states.contains(MaterialState.disabled)
                                ? null
                                : Colors.blue),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          Navigator.of(context).pushNamed('/answer');
                        }
                      },
                      child: const Text('Sign in'),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyFormApp extends StatelessWidget {
  const MyFormApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zemi-A Form',
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const Home(),
        '/answer': (context) => const MyForm(),
      },
    );
  }
}

void main() {
  runApp(const MyFormApp());
}
