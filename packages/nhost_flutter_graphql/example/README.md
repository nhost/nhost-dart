# Nhost GraphQL Support for Flutter Examples

* [Simple GraphQL example](https://github.com/nhost/nhost-dart/tree/main/packages/nhost_flutter_graphql/example/lib/simple_graphql_example.dart): Demonstrates establishing a GraphQL connection, and interaction with widgets from the `graphql` package
* [Todos Quick Start example](https://github.com/nhost/nhost-dart/tree/main/packages/nhost_flutter_graphql/example/lib/todos_quick_start_example.dart): A Flutter implementation of the [Nhost Quick Start app](https://docs.nhost.io)

## Getting Started

The "Todos Quick Start example" requires the following schema:

```sql
CREATE TABLE public.todos
(
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    name text COLLATE pg_catalog."default" NOT NULL,
    is_completed boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
	updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT todos_pkey PRIMARY KEY (id),
)

TABLESPACE pg_default;

ALTER TABLE public.todos
    OWNER to postgres;

CREATE TRIGGER set_public_todos_updated_at
    BEFORE UPDATE
    ON public.todos
    FOR EACH ROW
    EXECUTE PROCEDURE public.set_current_timestamp_updated_at();

INSERT INTO public.todos VALUES ('1140916c-c1ff-4c2c-aa37-7dcab48600dc', '2021-03-12 00:27:37.100541+00', 'Walk the dog', true, '2021-03-12 00:27:37.100541+00', 'f8d9befd-c6c8-41b8-b975-bee7e457571d');
INSERT INTO public.todos VALUES ('4912f5d2-ec4d-4c5e-bd50-0e8ddb27a689', '2021-03-12 00:27:49.347099+00', 'Cut the grass', false, '2021-03-12 00:27:49.347099+00', 'f8d9befd-c6c8-41b8-b975-bee7e457571d');
INSERT INTO public.todos VALUES ('7b06fa71-c2cc-4026-b07b-5eea9e01d307', '2021-03-12 00:27:55.886203+00', 'Take out the garbage', true, '2021-03-12 00:27:55.886203+00', 'f8d9befd-c6c8-41b8-b975-bee7e457571d');
INSERT INTO public.todos VALUES ('f98b73c9-54d4-4156-89fd-4507169baf4b', '2021-03-12 00:27:06.917262+00', 'Feed the frog', false, '2021-03-12 00:45:53.420608+00', 'f8d9befd-c6c8-41b8-b975-bee7e457571d');
```
