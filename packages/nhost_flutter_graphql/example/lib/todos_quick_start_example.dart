/// Implementation of the Nhost Quick Start app in Flutter.
///
/// GETTING STARTED: Follow the Nhost Quick Start at
/// https://docs.nhost.io/quick-start to prepare the backend. You can ignore
/// the client-side JS, because this Flutter app takes on that responsibility.
library todos_quick_start_example;

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:nhost_sdk/nhost_sdk.dart';
import 'package:nhost_flutter_graphql/nhost_flutter_graphql.dart';

// Fill in these values with the Backend and GraphQL URL found on your Nhost
// project page.

const nhostApiUrl = 'https://backend-5e69d1d7.nhost.app';
const nhostGraphQLUrl = 'https://hasura-5e69d1d7.nhost.app/v1/graphql';

void main() {
  runApp(TodosQuickStartExample());
}

class TodosQuickStartExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // The NhostGraphQLProvider automatically provides connection information
    // to `graphql_flutter` widgets in its subtree.
    return NhostGraphQLProvider(
      nhostClient: NhostClient(baseUrl: nhostApiUrl),
      gqlEndpointUrl: nhostGraphQLUrl,
      child: MaterialApp(
        title: 'Nhost.io Todos Quick Start',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          // `Query`, along with other `graphql` widgets, automatically pick up
          // the connection information from the nearest NhostGraphQLProvider.
          body: App(),
        ),
      ),
    );
  }
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context);

    Widget widget;
    switch (auth.authenticationState) {
      case AuthenticationState.loggedIn:
        widget = TodosPage();
        break;
      case AuthenticationState.loggedOut:
        widget = LoginPage();
        break;
      default:
        widget = SizedBox();
        break;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: widget,
    );
  }
}

final getTodosSubscription = gql('''
  subscription {
    todos(order_by: {created_at: desc}) {
      id
      name
      is_completed
      created_at
      updated_at
    }
  }
''');

final addTodoMutation = gql(r'''
  mutation($todo: todos_insert_input!) {
    insert_todos(objects: [$todo]) {
      affected_rows
    }
  }
''');

final setTodoCompletedMutation = gql(r'''
  mutation($todo_id: uuid!, $is_completed: Boolean!) {
    update_todos_by_pk(
      pk_columns: {id: $todo_id},
      _set: {is_completed: $is_completed}
    ) {
      id
    }
  }
''');

final removeCompletedTodosMutation = gql(r'''
  mutation {
    delete_todos(where: {is_completed: {_eq: true}}) {
      affected_rows
    }
  }
''');

class TodosPage extends StatelessWidget {
  const TodosPage({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const spacer = SizedBox(height: 8);
    return Subscription(
      options: SubscriptionOptions(
        document: getTodosSubscription,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return Text('Loading…');
        if (!result.isConcrete) return SizedBox();

        final todos = (result.data['todos'] as List)
            .map((json) => Todo.fromJson(json))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Todos',
              style: TextStyle(fontSize: 24),
            ),
            spacer,
            AddTodoField(),
            spacer,
            Expanded(
              child: TodoList(todos: todos),
            ),
            spacer,
            TodoListActions(),
          ],
        );
      },
    );
  }
}

class AddTodoField extends StatefulWidget {
  @override
  _AddTodoFieldState createState() => _AddTodoFieldState();
}

class _AddTodoFieldState extends State<AddTodoField> {
  TextEditingController _todoNameController;

  @override
  void initState() {
    super.initState();
    _todoNameController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    _todoNameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: addTodoMutation,
      ),
      builder: (runMutation, result) {
        return TextFormField(
          controller: _todoNameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'What needs to be done?',
          ),
          onEditingComplete: () {},
          onFieldSubmitted: (name) {
            name = name.trim();
            if (name.isNotEmpty) {
              runMutation({
                'todo': {
                  'name': name,
                },
              });
              _todoNameController.clear();
            }
          },
        );
      },
    );
  }
}

class TodoList extends StatelessWidget {
  const TodoList({
    Key key,
    this.todos,
  }) : super(key: key);

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return Text('No todos yet');
    }

    return ListView(
      children: [
        for (final todo in todos) TodoTile(todo: todo),
      ],
    );
  }
}

class TodoTile extends StatelessWidget {
  TodoTile({Key key, @required this.todo}) : super(key: key);
  final Todo todo;

  @override
  Widget build(BuildContext context) {
    return Mutation(
      options: MutationOptions(
        document: setTodoCompletedMutation,
      ),
      builder: (runMutation, result) {
        return CheckboxListTile(
          title: Text(
            todo.name,
            style: todo.isCompleted
                ? TextStyle(
                    decoration: TextDecoration.lineThrough,
                  )
                : null,
          ),
          value: todo.isCompleted,
          onChanged: result.isLoading
              ? null
              : (flag) async {
                  runMutation({
                    'todo_id': todo.id,
                    'is_completed': flag,
                  });
                },
        );
      },
    );
  }
}

class TodoListActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = NhostAuthProvider.of(context);
    return Row(
      children: [
        TextButton(
          onPressed: () {
            auth.logout();
          },
          child: Text('Logout'),
        ),
        const SizedBox(width: 12),
        Mutation(
          options: MutationOptions(
            document: removeCompletedTodosMutation,
          ),
          builder: (runMutation, result) {
            return TextButton(
              onPressed: () {
                runMutation({}).networkResult;
              },
              child: Text('Clear Completed'),
            );
          },
        ),
      ],
    );
  }
}

class Todo {
  Todo({this.id, this.name, this.isCompleted});
  factory Todo.fromJson(dynamic json) {
    return Todo(
      id: json['id'],
      name: json['name'],
      isCompleted: json['is_completed'],
    );
  }

  final String id;
  final String name;
  final bool isCompleted;
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  TextEditingController emailController;
  TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void tryLogin() async {
    final auth = NhostAuthProvider.of(context);

    try {
      await auth.login(
          email: emailController.text, password: passwordController.text);
    } on ApiException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login Failed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: FocusTraversalGroup(
        policy: ReadingOrderTraversalPolicy(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onFieldSubmitted: (_) => tryLogin(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onFieldSubmitted: (_) => tryLogin(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: tryLogin,
              child: Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}
