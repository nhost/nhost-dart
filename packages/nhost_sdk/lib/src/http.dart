/// HTTP constants, so we don't have to depend on dart:io (ensuring we're
/// compatible with more platforms)
library http;

const contentTypeHeader = 'content-type';
const authorizationHeader = 'authorization';

const unauthorizedStatus = 401;
