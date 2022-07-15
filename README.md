# formsclient
The purpose of this project is to evaluate the pair-programming. **NOT FOR A PRACTICAL USE.**

This is client software for a forms-like system written in [Flutter 3](https://flutter.dev/).

## Features
Fetches a form from a server, displays it, users fill it, and users submit it to the server. That's it.

## Specs
Uses the following JSONs to communicate with a server.

A form to fetch:
```
(Response) := 
{
  result: "ok",
  id: (Form ID),
  form: (Form)
}

(Form) :=
{
  title: (Title),
  questions: [
    (Question)*
  ]
}

(Question) := (Textbox) | (Checkbox)

(Textbox) :=
{
  id: (Question ID),
  type: "text",
  explanation: (Question statement),
  selection: []
}

(Checkbox) :=
{
  id: (Question ID),
  type: "radio",
  explanation: (Question statement),
  selection: [
    {
      label: (Option index),
      value: (Option statement),
    }
  ],
}
```

An answer to submit:
```
(Answer) :=
{
  id: (Form ID),
  answers: [
    {
      id: (Question ID),
      type: (Class),
      value: (Value),
    }*
  ]
}
```

Collected answers to receive from a server (not implemented)
```
(Answers) :=
[
  (Answer)*
]
```
