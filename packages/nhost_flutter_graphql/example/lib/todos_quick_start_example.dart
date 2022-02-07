/// Implementation of the Nhost Quick Start app in Flutter.
///
/// GETTING STARTED: Follow the Nhost Quick Start at
/// https://docs.nhost.io/get-started to prepare the backend. You can ignore
/// the client-side JS, because this Flutter app takes on that responsibility.
library todos_quick_start_example;

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:nhost_flutter_auth/nhost_flutter_auth.dart';
import 'package:nhost_flutter_graphql/nhost_flutter_graphql.dart';

import 'config.dart';

void main() {
  runApp(TodosQuickStartExample());
}

class TodosQuickStartExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // The NhostGraphQLProvider automatically provides connection information
    // to `graphql_flutter` widgets in its subtree.
    return NhostGraphQLProvider(
      nhostClient: NhostClient(backendUrl: nhostUrl),
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
    final auth = NhostAuthProvider.of(context)!;

    Widget widget;
    switch (auth.authenticationState) {
      case AuthenticationState.signedIn:
        widget = TodosPage();
        break;
      case AuthenticationState.signedOut:
        widget = SignInPage();
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
    Key? key,
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
        if (result.hasException) {
          return Text('Error encountered while loading todos. Did you setup '
              'your backend using the quick-start at '
              'https://docs.nhost.io/get-started?');
        }

        final todos = (result.data!['todos'] as List)
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
  late TextEditingController _todoNameController;

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
    Key? key,
    required this.todos,
  }) : super(key: key);

  final List<Todo> todos;

  @override
  Widget build(BuildContext context) {
    if (todos.isEmpty) {
      return Text('No todos yet');
    }

    return ListView(
      children: [
        for (final todo in todos)
          if (!todo.isCompleted) TodoTile(todo: todo),
        for (final todo in todos)
          if (todo.isCompleted) TodoTile(todo: todo),
      ],
    );
  }
}

class TodoTile extends StatelessWidget {
  TodoTile({Key? key, required this.todo}) : super(key: key);
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
          onChanged: result!.isLoading
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
    final auth = NhostAuthProvider.of(context)!;
    return Row(
      children: [
        TextButton(
          onPressed: () {
            auth.signOut();
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
  Todo({
    required this.id,
    required this.name,
    required this.isCompleted,
  });
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

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController emailController;
  late TextEditingController passwordController;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: 'user-1@nhost.io');
    passwordController = TextEditingController(text: 'password-1');
  }

  @override
  void dispose() {
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void trySignIn() async {
    final auth = NhostAuthProvider.of(context)!;

    try {
      await auth.signInEmailPassword(
          email: emailController.text, password: passwordController.text);
    } on ApiException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign in Failed'),
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
              onFieldSubmitted: (_) => trySignIn(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: passwordController,
              decoration: InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              onFieldSubmitted: (_) => trySignIn(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: trySignIn,
              child: Text('Submit'),
            )
          ],
        ),
      ),
    );
  }
}
