import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

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
        selections = [for (var item in json['selection']!) item];

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'explanation': explanation,
        'selection': selections
      };
}

class MyFormModel {
  final String title;
  final List<Question> questions;

  const MyFormModel(this.title, this.questions);

  MyFormModel.fromJson(Map<String, dynamic> json)
      : title = json['title']!,
        questions = [for (var item in json['questions']!) item];

  Map<String, dynamic> toJson() => {'title': title, 'questions': questions};
}

class GetFormModel {
  final String result;
  final String id;
  final MyFormModel form;

  const GetFormModel(this.result, this.id, this.form);

  GetFormModel.fromJson(Map<String, dynamic> json)
      : result = json['result']!,
        id = json['id']!,
        form = json['form']!;

  Map<String, dynamic> toJson() => {'result': result, 'id': id, 'form': form};
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

class MyForm extends StatefulWidget {
  const MyForm({Key? key}) : super(key: key);

  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _formKey = GlobalKey<FormState>();

  // final _json = JSONForm.fromJson(jsonDecode(jsonString));
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

  /// タイトル
  Widget _title(String title) => Container(
        decoration: const BoxDecoration(
          color: Colors.black26,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.headline3,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: const Color.fromARGB(255, 255, 0, 0),
                    onPrimary: const Color.fromARGB(255, 0, 0, 0),
                  ),
                  onPressed: null, // 未実装
                  child: const Text('編集'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: const Color.fromARGB(255, 255, 0, 0),
                    onPrimary: const Color.fromARGB(255, 0, 0, 0),
                  ),
                  onPressed: null, // 未実装
                  child: const Text('集計'),
                ),
              ],
            ),
          ],
        ),
      );

  /// 質問項目
  Widget _formItem(Question question) => Container(
        decoration: const BoxDecoration(
          color: Colors.black26,
        ),
        child: Column(
          children: [
            Text(
              question.explanation,
              style: Theme.of(context).textTheme.headline4,
            ),
            question.type == 'text'
                ? TextFormField(
                    onSaved: (content) {},
                  )
                : CheckboxFormField(
                    options: question.selections,
                    onSaved: (selected) {},
                  ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Zemi-A Forms'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            _title(_formResponse.form.title),
            for (var item in _formResponse.form.questions) _formItem(item),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _formKey.currentState!.save(),
        tooltip: '送信',
        child: const Icon(Icons.send),
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
      home: const MyForm(),
    );
  }
}

void main() {
  runApp(const MyFormApp());
}
