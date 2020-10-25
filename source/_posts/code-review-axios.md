---
title: 'Code Review: Axios'
date: 2020-10-07 22:49:11
tags: 
    - JavaScript
    - Programming
    - Code Review
---

> This article is in a series of code review articles that take a
> deep look at a popular module and discus it's merits, flaws, and
> overall fitness for a task.

## Summary

[Axios](https://github.com/axios/axios) is a solid, battle tested, replacement for the deprecated `require.js`. I
recommend it despite the imperfections that I have summarized in this article.

The logic in this package is well thought out and meets my standards.  Some of
the more complex functions are arduous to read. This makes collaboration from
the development community difficult and undermines the overall effectiveness of
the project.

The interceptor system is a workable solution for extending the package
functions.  Personally, I have wrapped request/response to extend error reporting
and the updates felt natural and a seamless transition.

There are two test runners in the project: Mocha (for node.js) and Jasmine/Karma
(for browser testing). This is unnecessary as both test packages can run both
platforms. A large portion of the tests are written for jasmine and will not
run, without modification in the mocha test suite.  This prevents me from
showing full code coverage with out hacking on the tests (more on this later). 

Running `npm test` takes many minutes and fails, by default, if the developer
does not have the Opera browser installed. I can understand that an exhaustive
integration run in a multi-target package is a long process. Fleshing out the
Mocha test suite to run on the command line in a second npm script would
encourage test driven refactoring and make many of the improvements I outline
much simpler and safer.  Iterative, refactoring tests must be fast, sane, and
meaningful.  They need not be exhaustive. The exhaustive testing can be saved
for pre-release and proofing pull-requests.

The current version is `0.20.0`. There is no explicit roadmap for the project;
however, I do not see a reason for delay in assigning version `1.0.0` to this
release.


## About Reviewed Version & System


- Repository: https://github.com/axios/axios
- Reviewed Commit Hash: `6d05b96dcae6c82e28b049fce3d4d44e6d15a9bc`
- Average weekly downloads: 12 million
- Version: 0.20.0
- `du -sh dist`: 244K
- Dependencies: 1
    - follow-redirects
- Node: v14.10.1
- npm: 4.16.8
- uname -a
    - Linux morlock 5.4.0-7642-generic #46\~1598628707\~20.04\~040157c-Ubuntu x86\_64 GNU/Linux

Axios is a promise-based HTTP client. It is available for use in the
browser (wrapping around XMLHttpRequest) or in node.js (wrapping the
built in `http` module.

## Setup

```
✔ pilot@morlock ~/Projects/codereview % git clone https://github.com/axios/axios.git
Cloning into 'axios'...
...
... <snip>
...
✔ pilot@morlock ~/Projects/codereview % npm install

... <snip> npm WARN deprecated 18 messages
...

> iltorb@2.4.5 install /home/pilot/Projects/codereview/axios/node_modules/iltorb
> node ./scripts/install.js || node-gyp rebuild

...
... <snip> Complation messages for node_modules/iltorb
... <snip> package postinstall garbage
...

npm notice created a lockfile as package-lock.json. You should commit this file.
npm WARN notsup Unsupported engine for karma@1.7.1: wanted: {"node":"0.10 || 0.12 || 4 || 5 || 6 || 7 || 8"} (current: {"node":"14.10.1","npm":"6.14.8"})
npm WARN notsup Not compatible with your version of node/npm: karma@1.7.1
npm WARN optional SKIPPING OPTIONAL DEPENDENCY: fsevents@^1.2.7 (node_modules/chokidar/node_modules/fsevents):
npm WARN notsup SKIPPING OPTIONAL DEPENDENCY: Unsupported platform for fsevents@1.2.13: wanted {"os":"darwin","arch":"any"} (current: {"os":"linux","arch":"x64"})
npm WARN ajv-keywords@2.1.1 requires a peer of ajv@^5.0.0 but none is installed. You must install peer dependencies yourself.

added 975 packages from 1871 contributors and audited 978 packages in 61.395s

11 packages are looking for funding
  run `npm fund` for details

found 33 vulnerabilities (22 low, 10 high, 1 critical)
  run `npm audit fix` to fix them, or `npm audit` for details
```

Installed 975 packages. All but one are dev.

`axios` installs `bundlesize@^0.17.0`, which is a drop in
replacement for `du -sh` (if `du` required oAuth read/write access to your
github account). Bundlesize uses a hand full of compression modules, including
`iltorb`. `iltorb` is deprecated garbage. 

### NPM Audit Review

```
✔ pilot@morlock ~/Projects/codereview/axios % npm --no-color audit > audit.txt
```

I'm not going to detail all of the audit warnings, they are mostly from the
[`debug` package](https://github.com/visionmedia/debug/pull/504/files) and it's
[DDoS Regex](https://npmjs.com/advisories/534).

The first High level security threat is from installing the `karma` test runner:

```
✘ pilot@morlock ~/Projects/codereview/axios % npm ls ws
axios@0.20.0 /home/pilot/Projects/codereview/axios
└─┬ karma@1.7.1
  └─┬ socket.io@1.7.3
    ├─┬ engine.io@1.8.3
    │ └── ws@1.1.2 
    └─┬ socket.io-client@1.7.3
      └─┬ engine.io-client@1.8.3
        └── ws@1.1.2  deduped
```

That is an extremely old version of `ws`. [It has been
fixed](https://www.npmjs.com/advisories/550)

I love `lodash` for the creativity of it's code base, the way the developers
step up to the challenge of being faster than native, but never user it. NPM
awards `lodash`'s prototype pollution (actually polyfils) a `High` level alert.

`karma` also depends on an old version of `chokidar`, but [new chokidar is way
cooler](https://paulmillr.com/posts/chokidar-3-save-32tb-of-traffic/).

The `Critical` alert award goes to: `webpack-dev-server` ... [kind of a let
down](https://npmjs.com/advisories/725)

[`parsejson` is installed](https://npmjs.com/advisories/528)

I went into all the depth here because it is important to note that while all of
these dependencies are dev only, they are eliminated by just updating the
dependencies[^1]. This is a bad code smell and indicator of lazy development cycles. 


## Running the tests

```
✘ pilot@morlock ~/Projects/codereview/axios % npm test

> axios@0.20.0 test /home/pilot/Projects/codereview/axios
> grunt test && bundlesize

Running "eslint:target" (eslint) task

Running "mochaTest:test" (mochaTest) task


...
... <snip> Test list
...

  29 passing (730ms)
  1 pending


Running "karma:single" (karma) task
Running locally since SAUCE_USERNAME and SAUCE_ACCESS_KEY environment variables are not set.
(node:26309) Warning: Accessing non-existent property 'VERSION' of module exports inside circular dependency
(Use `node --trace-warnings ...` to show where the warning was created)
Hash: f4683f5fa2953dc3a97c
Version: webpack 1.15.0
Time: 27ms
webpack: Compiled successfully.
webpack: Compiling...
webpack: wait until bundle finished: 
<snip>
Hash: 17b067e2f01905fd51bf
    Version: webpack 1.15.0
Time: 844ms
<snip>

webpack: Compiled successfully.
07 10 2020 23:56:29.288:INFO [karma]: Karma v1.7.1 server started at http://0.0.0.0:9876/
07 10 2020 23:56:29.289:INFO [launcher]: Launching browsers Firefox, Chrome, Safari, Opera with unlimited concurrency
07 10 2020 23:56:29.294:INFO [launcher]: Starting browser Firefox
07 10 2020 23:56:29.311:INFO [launcher]: Starting browser Chrome
07 10 2020 23:56:29.328:INFO [launcher]: Starting browser Safari
07 10 2020 23:56:29.351:INFO [launcher]: Starting browser Opera
07 10 2020 23:56:29.388:ERROR [launcher]: No binary for Safari browser on your platform.
  Please, set "SAFARI_BIN" env variable.
07 10 2020 23:56:32.140:INFO [Chrome 85.0.4183 (Linux 0.0.0)]: Connected on socket OZh8d5JZl6lqIyL8AAAA with id 4718835
................................................................................
................................................................................
................................................................................
......
Chrome 85.0.4183 (Linux 0.0.0): Executed 246 of 246 SUCCESS (2.522 secs / 2.462 secs)
07 10 2020 23:56:35.007:INFO [Firefox 81.0.0 (Ubuntu 0.0.0)]: Connected on socket -qEkpSILYreupv-OAAAB with id 87695166
................................................................................
................................................................................
................................................................................
......
Firefox 81.0.0 (Ubuntu 0.0.0): Executed 246 of 246 SUCCESS (2.512 secs / 2.455 secs)

08 10 2020 00:00:29.394:WARN [launcher]: Opera have not captured in 240000 ms, killing.
08 10 2020 00:00:31.398:WARN [launcher]: Opera was not killed in 2000 ms, sending SIGKILL.
08 10 2020 00:00:33.400:WARN [launcher]: Opera was not killed by SIGKILL in 2000 ms, continuing.
TOTAL: 492 SUCCESS
Warning: Task "karma:single" failed. Use --force to continue.

Aborted due to warnings.
npm ERR! Test failed.  See above for more details.
```

All tests passed... Except for the Opera tests; but I don't have the opera
browser installed, nor does anyone else.

It is interesting to note that karma detected immediately that I do not have
Safari installed; but took over two minutes to not find Opera.  This is an old
version of karma so I can not criticise.

One of the mocha tests is skipped: `should support sockets`. Setting this test to
run passes[^2].

## Code Coverage

This was not as straight forward as I thought it would be. The `package.json`
has an entry for `coveralls` but the `lcov` file wasn't generated by the test
run. Looking in `node_modules` I don't see an entry for `blanket.js`. *Another
bad smell.* Checking the `travis-ci` runs for the project they all error on `npm
run coveralls`. 

Let's live dangerously:

```
✘ pilot@morlock ~/Projects/codereview/axios % npx nyc@latest npm test
npx: installed 141 in 5.972s

> axios@0.20.0 test /home/pilot/Projects/codereview/axios
> grunt test && bundlesize

Running "eslint:target" (eslint) task

Running "mochaTest:test" (mochaTest) task
...
... <snip> Test list
...


-------------------------|---------|----------|---------|---------|-----------------------------------
File                     | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s                 
-------------------------|---------|----------|---------|---------|-----------------------------------
All files                |   79.21 |    62.78 |   79.44 |   79.73 |                                   
 axios                   |   33.33 |    11.36 |      40 |   34.69 |                                   
  Gruntfile.js           |   43.75 |        0 |      50 |      50 | 92-101                            
  index.js               |     100 |      100 |     100 |     100 |                                   
  karma.conf.js          |   26.47 |     11.9 |   33.33 |   26.47 | 7,20-109,111-115                  
 axios/lib               |   85.71 |    72.94 |   82.35 |   85.22 |                                   
  axios.js               |   90.91 |      100 |   33.33 |   90.91 | 36,46                             
  defaults.js            |   88.57 |    82.14 |     100 |   88.57 | 20,44,47-48                       
  utils.js               |   82.26 |    68.42 |   83.33 |   81.03 | 73,95,130,190-214,235,241,280,284 
 axios/lib/adapters      |   93.88 |    78.69 |     100 |    95.8 |                                   
  http.js                |   93.88 |    78.69 |     100 |    95.8 | 42,46,93,118,122,164              
 axios/lib/cancel        |   84.62 |       50 |   88.89 |   84.62 |                                   
  Cancel.js              |      80 |        0 |      50 |      80 | 14                                
  CancelToken.js         |   84.21 |       50 |     100 |   84.21 | 13,25,38                          
  isCancel.js            |     100 |      100 |     100 |     100 |                                   
 axios/lib/core          |   87.32 |    74.65 |   78.79 |   87.32 |                                   
  Axios.js               |   75.68 |    56.25 |   66.67 |   75.68 | 31-32,42-45,53,57,68-69           
  InterceptorManager.js  |   53.85 |        0 |      40 |   53.85 | 18-22,31-32,46-47                 
  buildFullPath.js       |     100 |      100 |     100 |     100 |                                   
  createError.js         |     100 |      100 |     100 |     100 |                                   
  dispatchRequest.js     |   95.65 |    68.75 |     100 |   95.65 | 69                                
  enhanceError.js        |      90 |      100 |      50 |      90 | 24                                
  mergeConfig.js         |     100 |    95.83 |     100 |     100 | 15                                
  settle.js              |   83.33 |       80 |     100 |   83.33 | 17                                
  transformData.js       |     100 |      100 |     100 |     100 |                                   
 axios/lib/helpers       |   40.82 |    17.86 |   58.33 |   39.58 |                                   
  bind.js                |     100 |      100 |     100 |     100 |                                   
  buildURL.js            |   13.79 |     4.55 |      25 |   13.79 | 6,29-69                           
  combineURLs.js         |     100 |       50 |     100 |     100 | 11                                
  isAbsoluteURL.js       |     100 |      100 |     100 |     100 |                                   
  normalizeHeaderName.js |   66.67 |       75 |     100 |   66.67 | 8-9                               
  spread.js              |   33.33 |      100 |       0 |   33.33 | 24-25                             
-------------------------|---------|----------|---------|---------|-----------------------------------
```

Not bad for a zero config nyc run. 

[See the full report here](/~timemachine/codereview/axios@0.20.0/)


## Digging In

Now that all that boilerplate is out of the way let's look though the code.
File by file:

### [lib/axios.js](/~timemachine/codereview/axios@0.20.0/lib/axios.js.html)

The `package.json` lists the default entry point as `/index.js` but that just
exports `lib/axios.js`. 

This is a general module building/exporting file. A default instance is created:
`axios` and then some other helpers are glued onto it.

1. axios: for the simple *requarian*, `cosnt axios = require('axios');`
2. axios.Axios: for *classical* `new Axios()` constructing.
3. axios.create: for the *[Crockfordian](https://crockford.com/javascript/prototypal.html)*.

The bizarre part of this is that all of the above give you different results.
The requarian form is constructed with a set of defaults from
`lib/defaults.js`; the classical constructor has no defaults; and
`axios.create` merges the supplied configuration with the defaults.


### [lib/defaults.js](/~timemachine/codereview/axios@0.20.0/lib/defaults.js.html)

Simple and sane defaults. However, the
[`getDefaultAdapter()`](/~timemachine/codereview/axios@0.20.0/lib/defaults.js.html#L16)
function affords me the opportunity to point out one of the stinkiest code
smells: *All if … else if constructs shall be terminated with an else clause.*
(See MISRA-C:2004, Rule 14.10, no online links, sorry).

This function should be terminated with an `else { throw new Error('Axios does
not support this platform') }` clause. That uncaught fall though leaves the
default adapter as `undefined` and the application in an unknown state.

#### Dynamic Imports

While picking on `getDefaultAdapter()`, there are two synchronous `require`
calls. First, I have to say that putting require calls deep in function logic is
a red flag; don't do it, ever. Secondly, it's fine to do it here...

Let me explain by assessing the 3 potential code paths, from the bottom up:

1. The default path: As I explained above the default path is to just return
   `undefined`. No harm from the synchronous calls.
2. Browsers: In the context of the browser the `require` function is provided by
   webpack. It is a synchronous function; however, webpack barfs all the
   javscript assets into the memory on page load. Thus, a synchronous require,
   in this context doesn't result in a bad turn[^3].
3. Node.js: [node's module
   resolution](https://github.com/nodejs/node/blob/master/lib/internal/modules/cjs/loader.js#L717)
   uses a caching system that only reads the file once from disk, the first time
   it is encountered. All other requests to `require` for the same file will
   return the object that was previously loaded. This creates a large number of
   blocking turns early in the application life cycle, but as long as you keep
   all of the require statements up at the top level of your file the turns will
   smoothen out once all the files are sourced.

   This seems like a contradiction. However, the call to `getDefaultAdapter()`
   *is* at the top level, when the file loads. We can observe that it is the same
   event loop turn that loads the other requires in this file (`utils` and
   `normalizeHeaderName`) and the call to load the http adapter.

My final verdict: this is a *good* example of multi-platform, dynamic
requirement retrieval in CommonJS. ES Modules also have [dynamic
imports](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/import#Dynamic_Imports).
However, the `import()` function in ESM is asynchronous so refactoring this
package to a module will require some additional state management.

#### [`transformResponse`](/~timemachine/codereview/axios@0.20.0/lib/defaults.js.html#L57)

`transformResponse` has a laughable JSON.parse() usage that should really be
sniffing the content-type header to avoid parsing XML/HTML as JSON.

### [lib/utils.js](/~timemachine/codereview/axios@0.20.0/lib/utils.js.html)

The bulk of this file is `is*` duck-typing functions. These are great helpers
for when you don't know the browser you are targeting. I'm happy to see these
in the package as opposed to another dependency. 

Some *utils* exist natively across all the supported browsers and should be
removed or wrap the native functions:

 - Array.isArray()
 - Array.prototype.forEach()
 - String.prototype.trim() which also removes: `\uFEFF` and `\xA0`, ~LMFAO~.

Don't copy `isNumber`, it's not the best way to do that. There is no best way to
write `isNumber` in JavaScript so you should consider the usefulness of
`Number.isFinite()`, `Number.isNaN()`, and (if you expect absolute values over 9
quadrillion) `Number.isSafeNumber()`.

My last thought on this file is not a knock on axios. It is a knock on Unicode,
and it's byte-order-mark. [They must
go](/~timemachine/codereview/axios@0.20.0/lib/utils.js.html#L315). I do
recommend that the `stripBOM` function assert it was passed a string before
modifying it.


### lib/helpers/

I'm confused. There is a `lib/utils.js` and a `lib/helpers/*`. Another sign of
copy/pasta? ... Let's dig in.

#### [lib/helpers/bind.js](/~timemachine/codereview/axios@0.20.0/lib/helpers/bind.js.html)

"Clean your ears out and listen close sonny ... Back in my day, before
JavaScript had *splats* we had this mysterious thing called the `arguments`
array. We never knew where it came from but it was always there. And even if I
called it an *array* it wasn't really an array but more like an object, with
numerical indexes..."

Targeting old browsers is the pits. It forces you to make hack helper functions
like bind. Necessary evil for pre-IE 9 support[^4].

Fortunately, axios doesn't care about browsers that old. This should go.

#### [lib/helpers/buildURL.js](/~timemachine/codereview/axios@0.20.0/lib/helpers/buildURL.js.html)

This file looks great ... Except maybe this line: `replace(/%20/g, '+').` ...
Whatever floats ya boat.


#### [lib/helpers/combineURLs.js](/~timemachine/codereview/axios@0.20.0/lib/helpers/combineURLs.js.html)

Needs to check that `baseURL` is defined (and a string) before calling
`.replace()` on it.

#### [lib/helpers/isAbsoluteURL.js](/~timemachine/codereview/axios@0.20.0/lib/helpers/isAbsoluteURL.js.html)

If you take the time to read the Regex it follows the spec. I shy away from
lengthy Regular Expressions. The logic is hard to test, hard to debug, and prone
to misinterpreted readings by other developers.

#### [lib/helpers/normalizeHeaderName.js](/~timemachine/codereview/axios@0.20.0/lib/helpers/normalizeHeaderName.js.html)

This function takes an object of `[key: string]: string` properties and a second
argument of a key. It then changes the spelling of the key in first argument to
match the capitalization of the second argument.

All header keys in HTTP should be treated as lower case. A more sensible act is
to take the input headers and convert them all to lowercase. Then use the
lowercase forms in all interactions. Better still would be to create an
enumeration of the headers axios cared about an then only use references to the
enumeration.

#### [lib/helpers/spread.js](/~timemachine/codereview/axios@0.20.0/lib/helpers/spread.js.html)

If you are a JavaScript novice, I can only explain the function in
`./helpers/spread.js` by saying: "It allows you to not type `null` when using
Function.prototype.apply()."

The documentation states this function is deprecated. It should log a warning
when called.

### lib/adapters

To allow interoperability between Browser and Node.js the *Adapter* pattern is used, or maybe it's the *Abstract Factory* pattern. ([But, what's in a name?](https://martinfowler.com/bliki/TwoHardThings.html)).

According to the [Gang of Four](https://en.wikipedia.org/wiki/Design_Patterns)
use an Abstract Factory to:

> Provide an interface for creating families of related or dependant objects
> without specifying their concrete classes.

The
[README.md](https://github.com/axios/axios/tree/6d05b96dcae6c82e28b049fce3d4d44e6d15a9bc/lib/adapters)
does a great job of defining the contract for all adapters to agree.

#### [lib/adapters/http.js](/~timemachine/codereview/axios@0.20.0/lib/adapters/http.js.html)

I'll start off my critique by pointing out: [The second edition of Martin
Fowler's "Refactoring"](https://martinfowler.com/articles/refactoring-2nd-ed.html)
uses JavaScript for its examples.

The cyclomatic complexity of `httpAdapter` is 42, according to JSHint. That's
just too much. There are some easy wins here for refactoring:

- Creating a new function for converting POST data to a Buffer drops the
  complexity by six. The resulting function is easier to test.
- Transforming the `config.auth` object and jamming it into the URL totals
  *ten* paths. Not as easy to refactor as there are some overlapping concerns: 
    - resolve the `username` and `password`
    - parse the URL
    - ~coalesce~ ignore the previous `username` and `password` if the URL has
      its own
    - continue to use the parsed URL over the next 90 lines
- Proxy configuration is complex; 60 lines and 13 paths.
- Finally, the callback to `transport.request()` should be it's own function,
  and possibly in it's own file.

#### [lib/adapters/xhr.js](https://github.com/axios/axios/blob/6d05b96dcae6c82e28b049fce3d4d44e6d15a9bc/lib/adapters/xhr.js)

Another grizzly adapter file. *Twenty-three* cyclomatic complexity value. I'll
avoid the exhaustive refactoring analysis but will mention there is some clean
up of the user/password logic that should be plucked from these files and into a
helper.

I just can't nit-pick this file as much. Feature sniffing the version of
XMLHttpRequest is complex, by definition.

### lib/cancel

Axios reimplements [cancel-able
promises](https://github.com/axios/axios#cancellation). I'm most familiar with
[Bluebird.js's Cancellations](http://bluebirdjs.com/docs/api/cancellation.html).

Since Bluebird is providing its own definition of Promises it can safely augment
a Promise with a `.cancel()` function. Axios does not have this luxury, making
the cancellation functionality more complex.

#### [lib/cancel/Cancel.js](/~timemachine/codereview/axios@0.20.0/lib/cancel/Cancel.js.html)

A prototype-based class with two properties that mimics the `Error` class,
in JavaScript.

- `message`: A description of why the cancellation happened.
- `__CANCEL__`: Always true. Used to duck-type Cancel objects from Error
  objects.

I would not mind seeing this extend the `Error` class. The added features of
`Error` (specifically the stack trace) could come in handy.
Additionally/Alternatively the constructor could take a `reason` parameter that
is an instance of an error.


#### [lib/cancel/CancelToken.js](/~timemachine/codereview/axios@0.20.0/lib/cancel/CancelToken.js.html)

A CancelToken is an identifier that triggers the cancellation process. 

The class has a factory to create a `source` and a constructor that does not
return a `source`. Instead it returns a function. This is confusing. I
recommend:

- `CancelToken` should return a `source`. This would unify the two styles of
  cancellation. However it would also break backward-compatibility.
- Fix compatibility by making the source returned by the factory a function that
  can be called directly. Annotate the source code of why this sloppiness
  is present.
    - Optionally: warn about deprecation when `source` is called as a function.
      (there would be different styles of warning for Browser vs. Node.js so
      feasiblity is debatable)
- Update the documentation to only use the `source` style cancellation. 

### lib/core

Now that we have dissected the supporting characters, we can dive into the heart
of the matter.

#### [lib/core/transformData.js](/~timemachine/codereview/axios@0.20.0/lib/core/transformData.js.html)

This is a helper (should be moved to that folder?) to loop over the transform
configuration for the Requests and Responses. 

The first line of the function is an eslint suppression comment. Manipulating
the config of static analysis tools at run time is sometimes needed; however, it
should be the exception and accompanied by a large amount to explanation
comments.

It's such a short function I'll just show you how this function should be
changed. I'll also rename the ambiguous variable names to ease my sanity:

```
module.exports = function(data, headers, transforms) {
    var result = data;
    utils.foreach(transforms, function (transform) {
        result = transform(result, headers);
    });
    return result;
};
```

In this trivial function, the usefulness of the `no-param-reassign` seems
suspect. Function bodies should treat all parameters as immutable, never assign
new values to them and it is absolutely crucial to never preform property
reassignment to parameters. Function purity is one of the best defenses we have
against defects.

Like I said, this small function is easy to understand and there is little
chance of a bug finding its way in here, but practicing proper habits when the
complexity is low sets us up for success when tackling the 42 headed hydra of
`lib/adapters/http.js`.

#### The error resolution tango

I'll explain the next few files as a group.

 - [lib/core/settle.js](/~timemachine/codereview/axios@0.20.0/lib/core/settle.js.html)
 - [lib/core/createError.js](/~timemachine/codereview/axios@0.20.0/lib/core/createError.js.html)
 - [lib/core/enhanceError.js](/~timemachine/codereview/axios@0.20.0/lib/core/enhanceError.js.html)

The two adapters (xml and http) both pass their responses along with the promise
callbacks to `settle`. Passing resolve/reject to a function is a bit thick.
Settle can just return a promise, if it needs asynchrony (it doesn't). 

Settle looks for the existence of the dubiously named: `validateStatus`
function and calls it to determine if the response was a success or error.
`validateStatus` takes one argument: the HTTP Status Code of the response. By
default a response is deemed a failure if its status code is between 200 and
299 (inclusive).

I think this `validateStatus` stuff is all *Feature-Request-Duct-Tape* and not
well thought out. Here is my suggestion: pass the whole response to
`validateStatus` as a second argument.

If `validateStatus` deems the response a failure, the response is passed (as
constituent parts) to `createError`. 

`createError` is correctly named as an error factory. It instantiates a new
Error object and then passes the error along with it's the other arguments to
`enhanceError`.

`enhanceError` adds the request config, response code, complete request, complete
response, and a new property (`isAxiosError`) to the error object before doing
something that is seemingly bizarre: it arguments the error with a new function
called, `toJSON()` that just makes a copy of it's self...But why[^6]? 

Take this example from the node REPL:

```
> JSON.stringify(new Error('bad thing'));
'{}'
```

Yep. You can't encode an `Error` object as JSON...*sadface*...Luckily, JSON
provides a canonical way of tackling the problems of JavaScript. The `stringify`
function inspects the objects (recursively) for a `toJSON` method. If found the
result of calling `toJSON` is encoded in lieu of the parent object:

```
> const e = new Error('bad thing');
undefined
> e.toJSON = function () { return this.name + ': ' + this.message; }
[Function (anonymous)]
> JSON.stringify(e);
'"Error: bad thing"'
```

You can see how node.js [handles calling `console.log` on an error](https://github.com/nodejs/node/blob/70834250e83fa89e92314be37a9592978ee8c6bd/lib/internal/util/inspect.js#L1176),
and other edge cases [deep in the bowels of
`formatRaw`](https://github.com/nodejs/node/blob/70834250e83fa89e92314be37a9592978ee8c6bd/lib/internal/util/inspect.js#L806).

Looking at the locations there `createError` and `enhanceError` are used through
the code base, I can stomach their existence. One problem I have, generally,
with Error factories is they botch the stack trace. 

#### [lib/core/buildFullPath.js](/~timemachine/codereview/axios@0.20.0/lib/core/buildFullPath.js.html)

[This looks familiar](#lib-helpers-combineURLs-js)

Let's compare:

- buildFullPath:

    ```
    module.exports = function buildFullPath(baseURL, requestedURL) {
      if (baseURL && !isAbsoluteURL(requestedURL)) {
        return combineURLs(baseURL, requestedURL);
      }
      return requestedURL;
    };
    ```

- combineURLs:

    ```
    module.exports = function combineURLs(baseURL, relativeURL) {
      return relativeURL
        ? baseURL.replace(/\/+$/, '') + '/' + relativeURL.replace(/^\/+/, '')
        : baseURL;
    };
    ```

A quick search of the source code and the only usage of `combineURLs` is *in*
`buildFullPath`. In-line it! 

Also, rename `buildFullPath`, it is too similar to
[`buildURL`](#lib-helpers-buildURL-js).


#### [lib/core/mergeConfig.js](/~timemachine/codereview/axios@0.20.0/lib/core/mergeConfig.js.html)

Gonna pull out the *yellow card*. Up to this point I have seen much-a-do about
supporting IE 6, 7, and 8. But here we see calls to `Object.keys` which pins the
compatibility to IE 9+. 

(Editor's Note: the README only claims compatibility for IE 11+)

Cloning objects is needlessly hard in JavaScript (how many versions before
`Object.prototype.clone()`? ...its possible). If you have need of such arcane
transformations study the [MDN page on the subject](https://wiki.developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Object/assign).

Honestly, if you can't `Object.assign(a, JSON.parse(JSON.stringify(b)));` what's
the point of living? (no, that doesn't work)

#### [lib/core/dispatchRequest.js](/~timemachine/codereview/axios@0.20.0/lib/core/dispatchRequest.js.html)

These files are getting *meaty*. There is a nice example of a [cross-cutting
concern](https://en.wikipedia.org/wiki/Cross-cutting_concern) here. Everyplace
where there may be a new turn in the event loop a check to
`throwIfCancellationRequested` shows up.

Remember when I said that [you get different configurations depending on how you
instantiate the `axios` object](#lib-axios-js)? The bug materializes into [line
50](/~timemachine/codereview/axios@0.20.0/lib/core/dispatchRequest.js.html#L50).

#### [lib/core/InterceptorManager.js](/~timemachine/codereview/axios@0.20.0/lib/core/InterceptorManager.js.html)

I could fan-boy all over the InterceptorManager all day. This class allows the
developer to decorate (add pre/post hooks to) the request. We will see this in
action in Axios.js.

#### [lib/core/Axios.js](/~timemachine/codereview/axios@0.20.0/lib/core/Axios.js.html)

Shout out to the power of prototypal inheritance: Lines 73 - 93.

The
[constructor](/~timemachine/codereview/axios@0.20.0/lib/core/Axios.js.html#L9)
makes the config accessible from the incorrectly named `defaults` property. Then
sets up the interceptors.

You can see the *Chain of Responsibility Pattern*, as a literal `chain`
variable. The chain is initialized with the dispatcher and undefined (you need
an even number of links in the chain, because: *shenanigans*). All of the
pre-request interceptors are un-shifted to start of the chain (even numbers
again for a fulfilled or rejected promise). Likewise of the post-request
interceptors are pushed to the end of the chain. Finally, two of the
interceptor-callbacks are removed from the head of the chain and added as
*thenables* to a master promise (one for fulfilled and one for rejected). In
the case of the dispatcher it handles its own rejection so we need an extra
element in the chain *shenanigans!*.

The master promise resoles all the pre-request hooks, the dispatcher, and all
the post-request hooks in order. **Study this code till you understand how it
works!**

## In Closing

I use the axios library, professionally, to send business critical requests to
third-party servers. When software is critical to your business you must be
critical of the software. However, the majority of software available through
the Node Package Manager passes without scrutiny.

From the length of this article you can guess that this was a multi-week effort
to type up all my thoughts. I did as much research on my claims as I thought was
reasonable to give an accurate representation. The first draft was not perfect
and I have made revisions as my understanding of the source code evolved.

While passionate about code quality I also have a sense of humor; my hope is
that both aspects enrich the reading experience and that my wit does not
distract the reader.

Thank you to my proof readers and technical editors, without them this would be
awful.

I have included additional action items in some the footnotes and will update
them with links to any pull requests that result so that the reader can stay
abreast of my contributions.

[^1]: TODO: Update dependants; open PR.
[^2]: TODO: Pull request, re-adding the skipped test.
[^3]: A *bad turn* is when the browser/server/application's event loop becomes
  blocked. When blocked the application will become unresponsive for some period
  of time until the block clears.
[^4]: Roughly 1.0% of Browsers support XMLHttpRequest but not
  Function.prototype.bind.
[^5]: *Feature-Request-Duct-Tape* is a quick code fix-up to fill a feature
  request in the easiest possible way. Feature-Request-Duct-Tape usually smells
  of configuration based feature flags, copy-pasta, `if...return` blocks, and
  unrelated `elseif` predicates.
[^6]: TODO: Turn this in to a post with an example of `Error.prototype.toJSON()`
