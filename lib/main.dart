import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
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

class TextAnswer {
  final int id;
  final String type;
  final String value;
}

class RadioAnswer {
  final int id;
  final String type;
  
}

class AnswerModel {
  final String id;
  final List<Answer> answers;
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
  late Future<GetFormModel> futureForm;
  Future<GetFormModel> fetchForm(String id) async {
    final response =
        await http.get(Uri.parse('http://localhost:8080/get-form/$id'));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return GetFormModel.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load album');
    }
  }

  @override
  void initState() {
    super.initState();
    futureForm = fetchForm("0");
  }

  // final _json = JSONForm.fromJson(jsonDecode(jsonString));
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
        child: FutureBuilder<GetFormModel>(
          future: futureForm,
          builder: (context, snapshot) {
            if(snapshot.hasData){
              return ListView(
                children: [
                  _title(snapshot.data!.form.title),
                  for (var item in snapshot.data!.form.questions) _formItem(item),
                ],
              );
            } else if (snapshot.hasError){
              return Text('${snapshot.error}');
            }

            return const CircularProgressIndicator();
          },
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
