# formsclient
THIS IS AN EXPERIMENTAL PROJECT TO EXAMINE THE EFFECTIVENESS OF PAIR-PROGRAMMING. **NOT FOR A PRACTICAL USE.**

This is an client software for Forms-like system written in Flutter 3.

## Features
Fetches a form from a server, shows it, a user fills it, and submit it to the server. That's it.

## Specs
Uses the following JSONs to communicate with a server.

Form to fetch:
```
(返事) := 
{
  result: "ok"
  id: (フォームID)
  form: (フォーム)
}
(フォーム) :=
{
  title: (タイトル),
  questions: [
    (質問項目)*
  ]
}
(質問項目) := (テキストボックス) | (チェックボックス)
(テキストボックス) :=
{
  id: (質問ID),
  type: "text",
  explanation: (質問文),
  selection: []
}
(チェックボックス) :=
{
  id: (質問ID),
  type: "radio",
  explanation: (質問文),
  selection: [
    {
      label: (ラベル),
      value: (値),
    }
  ],
}
```

Answer to submit:
```
(回答) :=
{
  id: (フォームID),
  answers: [
    {
      id: (質問ID),
      type: (タイプ),
      value: (値),
    }*
  ]
}
(回答一覧) :=
[
  (回答)*
]
```