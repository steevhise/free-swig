const fs = require('fs');
const path = require('path');
const file = require('file');
const swig = require('../lib/swig');
const expect = require('expect.js');
const _ = require('lodash');

function isTest (f) {
  return /\.test\.html$/.test(f);
}

function isExpectation (f) {
  return /\.expectation\.html$/.test(f);
}

describe('Templates', function () {
  const casefiles = [];
  const locals = {
    alpha: 'Nachos',
    first: 'Tacos',
    second: 'Burritos',
    includefile: './includes.html',
    bar: ['a', 'b', 'c']
  };
  let tests;
  let expectations;
  let cases;

  file.walkSync(path.resolve(__dirname, 'cases'), function (start, dirs, files) {
    _.each(files, function (f) {
      return casefiles.push(path.resolve(start + '/' + f));
    });
  });

  tests = _.filter(casefiles, isTest);
  expectations = _.filter(casefiles, isExpectation);
  cases = _.groupBy(tests.concat(expectations), function (f) {
    return f.split('.')[0];
  });

  _.each(cases, function (files, c) {
    const test = _.find(files, isTest);
    const expectation = fs.readFileSync(_.find(files, isExpectation), 'utf8');

    it(c, function () {
      expect(swig.compileFile(test)(locals)).to.equal(expectation);
    });
  });

  it('throw if circular extends are found', function () {
    expect(function () {
      swig.compileFile(
        path.resolve(__dirname, 'cases-error/circular.test.html')
      )();
    }).to.throwError(/Illegal circular extends of ".*/);
  });

  it('throw with filename reporting', function () {
    expect(function () {
      swig.compileFile(
        path.resolve(__dirname, 'cases-error/report-filename.test.html')
      )();
    }).to.throwError(
      /in file .*tests\/cases-error\/report-filename-partial\.html/
    );
  });
});
