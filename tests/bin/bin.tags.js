function parse () {
  return true;
}

function compile (compiler, args, content) {
  return compiler(content) + '\n' + '_output += " tortilla!";';
}

exports.tortilla = {
  parse,
  compile,
  ends: true
};
