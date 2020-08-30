const {readFileSync, writeFileSync} = require('fs');
const {normalize} = require('path');

const root = __dirname + '/..';

const header = "---\ntitle: about\ndate: 2020-08-29 10:45:50\n---";
const body = readFileSync(root + "/README.md");
const path = normalize(root + "/source/about/index.md");

console.log(`Writing: ${path}`);

writeFileSync(path, header + "\n\n" + body);



