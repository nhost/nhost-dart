This package's API tests can run in two modes — recording, and playback.

If recording, the test will be run against a local Hasura Backend Plus instance.
Currently, this is set up to run against the backend created by the nhost-js-sdk
package, and as output produces a set of HTTP "fixtures" — recordings that can
be used without a server.

If in playback, the tests are run against that set of fixtures. This is the
default mode of operation.

In order to run in recording mode, set the RECORD_HTTP_FIXTURES environment
variable when running the tests:

```sh
RECORD_HTTP_FIXTURES=true pub run test
```
