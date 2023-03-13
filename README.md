<div align="center"># Nhost Packages for Dart & Flutter</div>

![Nhost](https://i.imgur.com/ZenoUlM.png)

<div align="center">

# Nhost

<a href="https://docs.nhost.io/#quickstart">Quickstart</a>
<span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
<a href="http://nhost.io/">Website</a>
<span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
<a href="https://docs.nhost.io">Docs</a>
<span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
<a href="https://nhost.io/blog">Blog</a>
<span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
<a href="https://twitter.com/nhost">Twitter</a>
<span>&nbsp;&nbsp;•&nbsp;&nbsp;</span>
<a href="https://nhost.io/discord">Discord</a>
<br />

  <hr />
</div>

**Nhost is an open source Firebase alternative with GraphQL,** built with the following things in mind:

- Open Source
- GraphQL
- SQL
- Great Developer Experience

Nhost consists of open source software:

- Database: [PostgreSQL](https://www.postgresql.org/)
- Instant GraphQL API: [Hasura](https://hasura.io/)
- Authentication: [Hasura Auth](https://github.com/nhost/hasura-auth/)
- Storage: [Hasura Storage](https://github.com/nhost/hasura-storage)
- Serverless Functions: Node.js (JavaScript and TypeScript)
- [Nhost CLI](https://docs.nhost.io/reference/cli) for local development

## Architecture of Nhost

<div align="center">
  <br />
  <img src="https://github.com/nhost/nhost/raw/main/assets/nhost-diagram.png"/>
  <br />
  <br />
</div>

Visit [https://docs.nhost.io](http://docs.nhost.io) for the complete documentation.

# Get Started

| Package                                                 |                                                                                                                                               |                                                                                                                                                                                                                                                                                                                                                       |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [nhost_dart](packages/nhost_dart)                       | Authentication, file storage, and serverless function API clients                                                                             | [![nhost_dart](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_dart.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_dart.yaml) [![nhost_dart Pub](https://img.shields.io/pub/v/nhost_dart)](https://pub.dev/packages/nhost_dart)                                                                   |
| [nhost_flutter_auth](packages/nhost_flutter_auth)       | Flutter widgets for exposing Nhost authentication state to your app                                                                           | [![nhost_flutter_auth](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_flutter_auth.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_flutter_auth.yaml) [![nhost_flutter_auth Pub](https://img.shields.io/pub/v/nhost_flutter_auth)](https://pub.dev/packages/nhost_flutter_auth)                   |
| [nhost_flutter_graphql](packages/nhost_flutter_graphql) | Flutter widgets for providing Nhost GraphQL connections, for use with the [graphql_flutter](https://pub.dev/packages/graphql_flutter) package | [![nhost_flutter_graphql](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_flutter_graphql.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_flutter_graphql.yaml) [![nhost_flutter_auth Pub](https://img.shields.io/pub/v/nhost_flutter_graphql)](https://pub.dev/packages/nhost_flutter_graphql)    |
| [nhost_graphql_adapter](packages/nhost_graphql_adapter) | GraphQL connection setup, for use with the [graphql](https://pub.dev/packages/graphql) package                                                | [![nhost_graphql_adapter](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_graphql_adapter.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_graphql_adapter.yaml) [![nhost_graphql_adapter Pub](https://img.shields.io/pub/v/nhost_graphql_adapter)](https://pub.dev/packages/nhost_graphql_adapter) |
| [nhost_gql_links](packages/nhost_gql_links)             | (Internal) Library-independent GraphQL link setup                                                                                             | [![nhost_gql_links](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_gql_links.yaml/badge.svg)](https://github.com/nhost/nhost-dart/actions/workflows/test.nhost_gql_links.yaml) [![nhost_gql_links Pub](https://img.shields.io/pub/v/nhost_gql_links)](https://pub.dev/packages/nhost_gql_links)                                     |
