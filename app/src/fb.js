'use strict';

const bindStyles = require('./styles');
const bindKeyboardShortcuts = require('./keyboard_shortcuts');
const bindSpellCheck = require('./spellcheck');
const bindNotifications = require('./notifications');

bindStyles();
bindKeyboardShortcuts();
bindSpellCheck();
bindNotifications();
