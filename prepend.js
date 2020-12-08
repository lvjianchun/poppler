var logger = function(){}

Module['setLogger'] = function(_logger) { logger = _logger; };
Module['print'] = function(message) { logger(message, 'stdout'); };
Module['printErr'] = function(message) { logger(message, 'stderr'); };
