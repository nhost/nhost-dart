This package's API tests can run in two modes — recording, and playback.

If recording mode, the test will be run against a local Nhost instance, whose
configuration is located in `test/backend`. The server can be started by using
running `nhost dev` in that directory.

If in playback, the tests are run against that set of fixtures. This is the
default mode of operation.

In order to run in recording mode, set the `RECORD_HTTP_FIXTURES` environment
variable when running the tests:

```sh
# Start the local Nhost server
cd test/backend
nhost dev &

# Run the tests
RECORD_HTTP_FIXTURES=true pub run test
```
