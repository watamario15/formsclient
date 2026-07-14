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
  final List<Selection>? selections;

  const Question(this.id, this.type, this.explanation, [this.selections]);

  Question.fromJson(Map<String, dynamic> json)
      : id = json['id']!,
        type = json['type']!,
        explanation = json['explanation']!,
        selections = json.containsKey('selection')
            ? [for (var item in json['selection']) Selection.fromJson(item)]
            : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'explanation': explanation,
        if (selections != null) 'selection': selections
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
  final String? id;
  final MyFormModel? form;
  final String? message;

  const GetFormModel(this.result, {this.id, this.form, this.message});

  GetFormModel.fromJson(Map<String, dynamic> json)
      : result = json['result']!,
        id = json.containsKey('id') ? json['id']! : null,
        message = json.containsKey('message') ? json['message']! : null,
        form = json.containsKey('form')
            ? MyFormModel.fromJson(json['form']!)
            : null;

  Map<String, dynamic> toJson() => {
        'result': result,
        if (id != null) 'id': id,
        if (message != null) 'message': message,
        if (form != null) 'form': form
      };
}

class Answer {
  int id;
  String type;
  String? textValue;
  Map<String, bool>? radioValue;

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
  final String? message;

  const AnswerResponse(this.result, this.id, this.message);

  AnswerResponse.fromJson(Map<String, dynamic> json)
      : result = json['result']!,
        id = json.containsKey('id') ? json['id'] : null,
        message = json['message']!;

  Map<String, dynamic> toJson() =>
      {'result': result, if (id != null) 'id': id, 'message': message};
}

class FormLocator {
  final String host, id;
  final AnswerModel? answer;

  const FormLocator(this.host, this.id, [this.answer]);
}

class CheckboxFormField extends FormField<Map<String, bool>> {
  CheckboxFormField({
    super.key,
    super.onSaved,
    super.validator,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
    Map<String, bool>? initialValue,
    required List<Selection> options,
  }) : super(
          initialValue: initialValue ?? {},
          builder: (state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var item in options)
                  CheckboxListTile(
                    title: Text(item.value),
                    value: state.value!
                        .putIfAbsent(item.label.toString(), () => false),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (flag) {
                      if (flag == null) return;
                      final newState = state.value!;
                      newState[item.label.toString()] = flag;
                      state.didChange(newState);
                    },
                  ),
              ],
            );
          },
        );
}

class AnswerScreen extends StatefulWidget {
  final String hostName, formID;
  const AnswerScreen({super.key, required this.hostName, required this.formID});

  @override
  State<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends State<AnswerScreen> {
  final _formKey = GlobalKey<FormState>();
  Future<GetFormModel>? _futureForm;
  late AnswerModel _answer;
  bool askOnBack = false;

  /*
  final _formResponse = const GetFormModel(
    'ok',
    id: 'someid',
    form: MyFormModel(
      'testform',
      'someid',
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
        Question(1, 'text', 'Hey! This is text!'),
      ],
    ),
  );
  */

  Future<GetFormModel> _fetchForm(String host, String id) async {
    final response =
        await http.get(Uri.parse('http://$host:8080/get-form/$id'));

    if (response.statusCode == 200) {
      final form = GetFormModel.fromJson(jsonDecode(response.body));
      if (form.result != 'ok') {
        throw Exception('Response is not OK '
            '(Result: "${form.result}", Message: "${form.message}").');
      }
      return form;
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
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: null, // 未実装
                    child: Text('Modify this form'),
                  ),
                  TextButton(
                    onPressed: null, // 未実装
                    child: Text('Show answers'),
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
                  '${question.id}. ${question.explanation}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              question.type == 'text'
                  ? TextFormField(
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onSaved: (content) {
                        for (var item in _answer.answers) {
                          if (item.id == question.id) {
                            item.textValue = content;
                            return;
                          }
                        }
                        _answer.answers
                            .add(Answer(question.id, question.type, content));
                      },
                    )
                  : CheckboxFormField(
                      options: question.selections!,
                      onSaved: (content) {
                        for (var item in _answer.answers) {
                          if (item.id == question.id) {
                            item.radioValue = content;
                            return;
                          }
                        }
                        _answer.answers
                            .add(Answer(question.id, question.type, content));
                      },
                    ),
            ],
          ),
        ),
      );

  @override
  void initState() {
    super.initState();
    _answer = AnswerModel(widget.formID, []);
    _futureForm = _fetchForm(widget.hostName, widget.formID);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // 回答が変更されていなければ、そのまま戻れる。
      // 変更されていれば、いったん戻る操作を止める。
      canPop: !askOnBack,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        // canPop が true で、すでに正常に戻った場合
        if (didPop) return;
    
        // canPop が false、つまり回答が変更されている場合
        final bool shouldPop =
          await showDialog<bool>(
            context: context,
            builder: (dialogContext) => SimpleDialog(
              title: const Text(
                'Your answer will be lost. Go back anyway?',
              ),
              children: [
                SimpleDialogOption(
                  child: const Text('Yes'),
                  onPressed: () {
                    Navigator.pop(dialogContext, true);
                  },
                ),
                SimpleDialogOption(
                  child: const Text('No'),
                  onPressed: () {
                    Navigator.pop(dialogContext, false);
                  },
                ),
              ],
            ),
          ) ??
          false;
    
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Zemi-A Forms'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FutureBuilder<GetFormModel>(
              future: _futureForm,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SizedBox(
                    width: 800,
                    child: Form(
                      key: _formKey,
                      onChanged: () {
                        if (!askOnBack) setState(() => askOnBack = true);
                      },
                      child: ListView(
                        children: [
                          _title(snapshot.data!.form!.title),
                          for (var item in snapshot.data!.form!.questions)
                            _formItem(item),
                        ],
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return SizedBox(
                    width: 800,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          '''Failed to fetch a form.
1. Check if you are connected to the internet and the server is online.
2. Check the server and ID you entered.
3. Contact the server maintainer with the following message:

${snapshot.error}''',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _formKey.currentState!.save();
            Navigator.of(context).pushNamed(
              '/answer/submit',
              arguments: FormLocator(widget.hostName, widget.formID, _answer),
            );
          },
          tooltip: 'Submit',
          child: const Icon(Icons.send),
        ),
      ),
    );
  }
}

class SubmitAnswer extends StatefulWidget {
  final String hostName, formID;
  final AnswerModel answer;
  const SubmitAnswer(
      {super.key,
      required this.hostName,
      required this.formID,
      required this.answer});

  @override
  State<SubmitAnswer> createState() => _SubmitAnswerState();
}

class _SubmitAnswerState extends State<SubmitAnswer> {
  Future<AnswerResponse>? _futureResponse;
  bool _didSucceed = false;

  Future<AnswerResponse> _submitAnswer(
    String host,
    String id,
    AnswerModel answer,
  ) async {
    final response = await http.post(
      Uri.parse('http://$host:8080/send-answer/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(answer),
    );

    if (response.statusCode == 200) {
      final ret = AnswerResponse.fromJson(jsonDecode(response.body));
      if (ret.result != 'ok') {
        throw Exception('Response is not OK '
            '(Result: "${ret.result}", Message: "${ret.message}").');
      }
      return ret;
    } else {
      throw Exception('Failed to submit your answer to $host.');
    }
  }

  @override
  void initState() {
    super.initState();

    _futureResponse = _submitAnswer(widget.hostName, widget.formID, widget.answer).then((response) {
      if (mounted) setState(() => _didSucceed = true);
      return response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // 送信失敗・送信中なら通常どおり戻れる。
      // 送信成功後は直接戻らず、コールバックでホームまで戻す。
      canPop: !_didSucceed,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_didSucceed) Navigator.of(context).popUntil(ModalRoute.withName('/'));
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Zemi-A Forms'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: FutureBuilder<AnswerResponse>(
              future: _futureResponse,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SizedBox(
                    width: 400,
                    height: 200,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            const Expanded(
                              child: FittedBox(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Saved your answer',
                                  style:
                                      Theme.of(context).textTheme.displaySmall,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return SizedBox(
                    width: 800,
                    height: 400,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Expanded(
                              child: FittedBox(
                                child: Icon(
                                  Icons.highlight_off,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Center(
                                child: Text(
                                  '''Failed to submit your answer.
1. Check if you are connected to the internet and the server is online.
2. Check the server and ID you entered.
3. Contact the server maintainer with the following message:

${snapshot.error}''',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _formKey = GlobalKey<FormState>();
  String? _hostName, _formID;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Zemi-A Forms'),
      ),
      body: Center(
        child: SizedBox(
          width: 400,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Card(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Sign in',
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        decoration:
                            const InputDecoration(hintText: 'Form server'),
                        onSaved: (value) {
                          _hostName = value;
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
                          _formID = value;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a form ID.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            Navigator.of(context).pushNamed(
                              '/answer',
                              arguments:
                                  FormLocator(_hostName!, _formID!, null),
                            );
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            Navigator.of(context).pushNamed(
                              '/answer',
                              arguments: FormLocator(_hostName!, _formID!),
                            );
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
      ),
    );
  }
}

class MyFormApp extends StatelessWidget {
  const MyFormApp({super.key});

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
        '/answer': (context) {
          final formLocator =
              ModalRoute.of(context)!.settings.arguments as FormLocator;
          return AnswerScreen(
            hostName: formLocator.host,
            formID: formLocator.id,
          );
        },
        '/answer/submit': (context) {
          final formLocator =
              ModalRoute.of(context)!.settings.arguments as FormLocator;
          return SubmitAnswer(
            hostName: formLocator.host,
            formID: formLocator.id,
            answer: formLocator.answer!,
          );
        }
      },
    );
  }
}

void main() {
  runApp(const MyFormApp());
}
