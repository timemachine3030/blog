---
title: The Cycle of Code, Test, Document
date: 2020-08-29 11:37:39
tags: 
 - Programming 
 - Testing
---

## History

I have been thinking about [Literate Programming](https://en.wikipedia.org/wiki/Literate_programming) for the last couple of weeks. Back in the early-to-mid 2000s I worked at a company where we used a *variant* of literate programming. There was an outline format that we used for all documentation. Everything from code comments to commit messages had to be written in this lightweight, parsable outline syntax.

The main project I worked on was safety critical black-box/white-box testing. Requirement traceability was at the core of all software written. Software requirements where tagged in *business requirements documents* (usually Word documents from the customer), and then a Software Requirement Specification  (SRS) document was generated. Here is an example:

```
- SRS-0123: Process X must only return values in a safe range
    - Dev Notes: 
        - Min an Max vaules for a range are defined in safe_ranges.h
	- Values outside of the safe range are clamped to the min/max value.
- SRS-0124: If Process X calculates a value more than 10% above the max safe 
  value, an error MUST be displayed to the user.
- SRS-0125: If Process X calculates a value less than the min safe value, 
  the min safe value is return instead.
```

It doesn't take a sophisticated parser to turn the above into an Object Model. Faced with the same task now I would modify the syntax slightly and use a YAML or Markdown parser[^1].

The test harness would take a similarly outlined document and generate the required C source code and header files. Specific unit tests had setup, tear down, and test code blocks[^2].

```
- Covers: SRS-0123
    - Sources: 
        - process_x.c
        - safe_ranges.h: test_ranges.h

    - Setup:

       ||||||||||
       ... Any setup would go here ...
       ||||||||||

    - Test:

       ||||||||||
       int result;

       result = calculate_x(args);
       TEST_EXPECT_EQUAL(result, SAFE_MIN_VALUE);
       ||||||||||

    - Teardown:

       ||||||||||
       ... Any cleanup would go here ...
       ||||||||||
```

In addition to generating C files the SRS document could be combined with test files to produce a traceability matrix, code coverage report, and a master testing document that had each requirement, the tests to ensure compliance, and the implementation source.

When everything you write can be parsed, computed, and generated into a new form your workflows gain a new power. Specifically, you can mash documents together or distill them into new assets.

## Current Problem

*I've written 3 API documents for third party developers in the last week.*

Three outside companies (integrators) want to interface with our system and need instruction on how to do so. The sticky bit is that we have different NDAs and SLAs with each of these integrators. Also, the bulk of our API is outside of the scope of what we want to share. Some of it is protected intellectual property, some is custom for just one integrator[^3].

There was duplication of effort in building these documents. An outline of a doc follows:

 1. Cover page
	- Title
	- Supported API [version](version)
	- Release date
	- Confidentiality statement
 2. Detailed change history of document
	- A table with the Release Date and Changes
 3. Document conventions
 4. Common error response codes, meanings, examples, and remedies
 5. Authentication requirements
 6. Endpoint descriptions
	- Method & URL
	- Parameters
	- Example request
	- Example response

Of the six top level bullet points three (*1, 3, 5*)  are the same in all documents. The *change history* is document specific; *Common errors* are the same in meaning, across documents, but may have different forms (XML[^4] or JSON); *Endpoint descriptions* contain the meat of the differences and the minimum of procedural generation must allow customizing these pages in each document.

## Inspirations

### Documentation Generators

[Doc Generators](https://en.wikipedia.org/wiki/Comparison_of_documentation_generators) are software packages the take annotations and function signatures from source files and generate documentation, often as html or pdf files.

One of the drawbacks of these techniques are that the annotations (usually in the form of block comments) are secondary to the source code. The documentation isn't a first class member of the file and ensuring that it remains accurate and up to date with bug fixes and changes to requirements can be a chore.

### perlpod

Perl's block comments have a taxonomy that is unusual for programming languages. This creates a single source file that is both an executable script and all the documentation for that script. Unlike with other inline documentation, POD feels front and center in the source files.

###  Swagger/OpenAPI

The [OpenAPI Specification](https://swagger.io/docs/specification/about/) is a YAML or JSON schema for describing API documentation. There are many tools and projects that can convert source files to to both API docs and server  endpoint stubs.

### WEB / weave / tangle

The [Web (programming system)](http://www.literateprogramming.com/knuthweb.pdf) by Donald Knuth is the original implementation of Literate Programming. WEB is a suite of programs, Weave and Tangle, that take a formatted file and generates either a TeX document (Weave) or a program source (Tangle).

## Solution In Progress

The text you are reading started as a Markdown file. I'm typing markdown in vim right now. As a well-structured document, I can extract blocks of text from this document with a simple parser and write those bits to a different file. That's how this file turns into both an html document and a snippet on this blog's homepage. Different nodes are used in different places.

I'm working on a syntax extension for Markdown that allows extraction and remixing code blocks.

Function:
```javascript
function announceWisdom(profound_thought) {
    console.log(profound_thought);
}
```

Usage:
```javascript
announceWisdom('Hello, World');
```

There we have two code blocks. One called 'Function' and one called 'Usage'. [Remarkable](https://www.npmjs.com/package/remarkable) and [Marked](https://www.npmjs.com/package/marked) are two satisfactory markdown parsers. I find that Remarkable is a little easier to extend. I'll use it, for now, but try not to overly couple my code it so that I can swap between the two or write my own if I can't get the features that I want.

This `markdownParser` function can be modified to change the parser that we use. A bit clumsy, as we are allowing the Remarkable library to dictate to shape of our token objects.

markdownParser:
```javascript
const {Remarkable} = require('remarkable');
const {readFileSync} = require('fs');

const markdownParser = function (filename) {
    const md = new Remarkable('full');
    const content = readFileSync(filename);
    const tokens = md.parse(content.toString('utf8'), {});
    return tokens;
}
```

The returned `tokens` is an array of [`ContentToken`](https://github.com/DefinitelyTyped/DefinitelyTyped/blob/master/types/remarkable/lib/index.d.ts#L397) objects.

Let's look at that `markdownParser` code block again. There are two distinct parts: (a) the `require` statements and (b) a function definition. If we stripped out the all the code blocks in this file and concatenated them together we would have a running script, but it would not be well organized. The order that you describe things is not always the order in which the compiler/interpreter wants them. This is fundamental in Donald Knuth's description of the Weave and Tangle programs. 

So far we have used simple names for the blocks: `Function`, `Usage`, `markdownParser`. We can standardize these into a syntax[^5], one that won't collide with other markdown syntax and allows us to: (1) signal that this is no ordinary code block, we need to do something with it, (2) a verb that describes what to do, (3) a noun that can act as a label or destination, and (4) the purpose of the code block, its *raison d'être*.

```
  (#save: "somefile.js":imports)
  (#save: "somefile.js":function-definitions) Definition of markdownParser
```
That parses into:

- verb: save
- label: imports
- purpose: somefile.js


I added some descriptive text to line two. That's an optional caption for the rendered code block.

Markdown standards don't have or reserve `(#...)` sequences. In general a parenthetical does not denote a behavior unless following `[]` for anchors, or `![]` for images. An octothorpe[^6] is equally meaningless; however, it is an escapable character. So if there is a need we can type (&#92;#...) and the parser will do the right thing.

(#save: parser.js:constants) Regular Expression to capture commands
```javascript
const reCmdCapture = /^\(#(?<cmd>[a-z][a-z_-]+)\s*:\s*["'`]?(?<purp>[^["'`:]+)["'`]?\s*:?\s*(?<label>[^\)]*)\)\s*(?<caption>[^\n]*)/;
function captureCommand(str) {
    const matches = str.match(reCmdCapture)
    return matches 
        ? {
            command: matches.groups.cmd,
            purpose: matches.groups.purp,
            label: matches.groups.label,
            caption: matches.groups.caption
        }
        : false;

}
```

That's one way to do it...so is:

(#save: parser.js:constants) Regular Expression to match commands
```javascript
const reCmdMatcher = /^\(#[^)]+\)/;
const reSplitOffCaption = /\)\s*/;
const reDirectiveSplitter = /\s*:\s*/;
const reCaptureUnquoted = /^(['"`])?(.+?)\1?$/;
function matchCommand(str) {
    const matches = str.match(reCmdMatcher);
    if (!!matches) {
        let [directive, caption] = str.split(reSplitOffCaption);
        let [command, purpose, label] = directive.substr(2).split(reDirectiveSplitter);
        purpose = purpose.match(reCaptureUnquoted)[2]; 
        return { command, purpose, label, caption };
    }
    return false;
}
```

(#save: test-parser.js:test) Test matcher and capture options.
```javascript
const { expect } = require('chai');

describe('Parsing', () => {
    const samples = [
        '(#save: "somefile.js":imports)',
        '(#save: "somefile.js":function-definitions) Definition of markdownParser',
        '(#save: parser.js:constants) Regular Expression to capture commands',
        'Will not match',
        'Also, not a match: (#save: "somefile.js":imports)'
    ];

    describe('Capture Style', () => {
        it('finds no captions', () => {
            expect(captureCommand(samples[0])).to.eql({
                command: 'save', 
                purpose: 'somefile.js', 
                label: 'imports', 
                caption: ''
            });
        });
        it('finds with captions', () => {
            expect(captureCommand(samples[1])).to.eql({
                command: 'save', 
                purpose: 'somefile.js', 
                label: 'function-definitions', 
                caption: 'Definition of markdownParser'
            });
        });

        it('finds, optional quotes around purpose/filename', () => {
            expect(captureCommand(samples[2])).to.eql({
                command: 'save', 
                purpose: 'parser.js', 
                label: 'constants', 
                caption: 'Regular Expression to capture commands'
            });
        });
        it('returns false if not match', () => {
            expect(captureCommand(samples[3])).to.eql(false);
        });

        it('ignores directives that are not in the first column', () => {
            expect(captureCommand(samples[4])).to.eql(false);
        });
    });
    describe('Matcher Style', () => {
        it('finds no captions', () => {
            expect(matchCommand(samples[0])).to.eql({
                command: 'save', 
                purpose: 'somefile.js', 
                label: 'imports', 
                caption: ''
            });
        });

        it('finds with captions', () => {
            expect(matchCommand(samples[1])).to.eql({
                command: 'save', 
                purpose: 'somefile.js', 
                label: 'function-definitions', 
                caption: 'Definition of markdownParser'
            });
        });

        it('finds, optional quotes around purpose/filename', () => {
            expect(matchCommand(samples[2])).to.eql({
                command: 'save', 
                purpose: 'parser.js', 
                label: 'constants', 
                caption: 'Regular Expression to capture commands'
            });
        });

        it('returns false if not match', () => {
            expect(matchCommand(samples[3])).to.eql(false);
        });

        it('ignores directives that are not in the first column', () => {
            expect(matchCommand(samples[4])).to.eql(false);
        });
    });
});
```

 [^1]: Maybe not ... our parser was so minimal that the self-test for it was easy to write/maintain.
 [^2]: A boon of this test harness that I have not seen in other package was the ability to turn off code coverage in the setup and tear down code blocks. Coverage was only recorded for actual testing.
 [^3]: A moment of weakness
 [^4]: My inclusion of XML is not an endorsement of the technology.
 [^5]: For the  hexo script to format the directives into `figcaption` see [the github project for this blog](https://github.com/timemachine3030/blog/blob/master/scripts/create-caption.js)
 [^6]: Vim's default English dictionary doesn't include this common term for a hash mark. The suggested replacement is `ectotherm`.
