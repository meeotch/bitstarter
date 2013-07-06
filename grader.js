#!/usr/bin/env node
/*
Automatically grade files for the presence of specified HTML tags/attributes.
Uses commander.js and cheerio. Teaches command line application development
and basic DOM parsing.

References:

 + cheerio
   - https://github.com/MatthewMueller/cheerio
   - http://encosia.com/cheerio-faster-windows-friendly-alternative-jsdom/
   - http://maxogden.com/scraping-with-node.html

 + commander.js
   - https://github.com/visionmedia/commander.js
   - http://tjholowaychuk.com/post/9103188408/commander-js-nodejs-command-line-interfaces-made-easy

 + JSON
   - http://en.wikipedia.org/wiki/JSON
   - https://developer.mozilla.org/en-US/docs/JSON
   - https://developer.mozilla.org/en-US/docs/JSON#JSON_in_Firefox_2
*/

var fs = require('fs');
var program = require('commander');
var cheerio = require('cheerio');
var rest = require('restler');
var HTMLFILE_DEFAULT = "index.html";
var CHECKSFILE_DEFAULT = "checks.json";

var asserFileExists = function(infile) {
    var instr = infile.toString();
    if (!fs.existsSync(instr)) {
        console.log("%s does not exist. Exiting.", instr);
        process.exit(1);   // http://nodejs.org/api/process.html#process_process_exit_code
    }
    return instr;
};

// load a file, return a buffer
var loadFile = function(htmlfile) {
    return fs.readFileSync(htmlfile);
};

// output JSON to console
var jsonOut = function(j) {
    console.log(JSON.stringify(j, null, 4));
}

var buildfn = function(url, checksfile) {
    var gradeURL = function(result, response) {
        if (result instanceof Error) {
            console.error('Error: ' + util.format(response.message));
        } else {
            console.error("Read from URL: %s", url);
            console.error(response);
            jsonOut(checkHtml(result, checksfile));
        }
    };
    return gradeURL;
};

var loadChecks = function(checksfile) {
    return JSON.parse(fs.readFileSync(checksfile));
};

var checkHtml = function(s, checksfile) {
    $ = cheerio.load(s);
    var checks = loadChecks(checksfile).sort();
    var out = {};
    for (var ii in checks) {
        var present = $(checks[ii]).length > 0;
        out[checks[ii]] = present;
    }
    return out;
};


var clone = function(fn) {
    // Workaround for commander.js issue.
    // http://stackoverflow.com/a/6772648
    return fn.bind({});
};

if (require.main == module) {
    program
        .option('-c, --checks <check-file>', 'Path to checks.json', clone(asserFileExists), CHECKSFILE_DEFAULT)
        .option('-f, --file [html_file]', 'Path to index.html', clone(asserFileExists), HTMLFILE_DEFAULT)
        .option('-u, --url [URL]', 'URL of file to be checked', null)
        .parse(process.argv);

    if (program.url) 
        rest.get(program.url).on('complete', buildfn(program.url, program.checks));
    else
        jsonOut(checkHtml(fs.readFileSync(program.file), program.checks));
} else {
    exports.checkHtml = checkHtml;
}
