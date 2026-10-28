const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

function page({tab = null, threads = [], ready = true} = {}) {
  const messages = [], observers = [], timers = [], listeners = {}, queries = [];
  const navigation = {matches: () => ready}, grid = {matches: () => ready};
  const document = {
    body: {}, visibilityState: 'visible', contains: () => true,
    addEventListener: (name, fn) => { listeners[name] = fn; },
    querySelector: selector => selector.includes('tablist') ? tab : selector.includes('grid') ? (ready ? grid : null) : navigation,
    querySelectorAll: selector => { queries.push(selector); return selector.includes('.x1spa7qu') ? threads.filter(t => t.unread) : threads.map(t => ({
      getAttribute: () => t.key,
      querySelector: selector => selector.includes('.x1spa7qu') ? (t.unread ? {} : null) : selector.includes('x14rh7hd') ? null : selector.includes('xlyipyv') ? {textContent: 'Person'} : {childNodes: [{nodeType: 3, textContent: t.text || 'hello'}]},
    })); },
  };
  const window = {addEventListener: document.addEventListener, webkit: {messageHandlers: {goofy: {postMessage: m => messages.push(m)}}}};
  class MutationObserver {
    constructor(fn) { this.fn = fn; }
    observe(element, options) { observers.push({element, options, fn: this.fn}); }
    disconnect() {}
  }
  vm.runInNewContext(fs.readFileSync(require.resolve('../goofy/content.js'), 'utf8'), {
    window, document, MutationObserver, Node: {TEXT_NODE: 3, ELEMENT_NODE: 1},
    console: {log() {}}, setTimeout: fn => {timers.push(fn); return timers.length;}, clearTimeout() {},
  });
  return {goofy: window.__GOOFY, messages, observers, listeners, queries, setReady: value => { ready = value; }, flush: () => { while (timers.length) timers.shift()(); }};
}

test('counts unread conversations when Messenger has no tab bar', () => {
  const p = page({threads: [{key: '/messages/t/1', unread: true}]});
  assert.equal(p.messages.find(m => m.type === 'badge')?.count, 1);
});

test('initial conversations establish a baseline before a new message arrives', () => {
  const threads = [{key: '/messages/t/1', unread: true, text: 'old'}];
  const p = page({tab: {getAttribute: () => 'true'}, threads});
  threads[0].text = 'new';
  p.goofy.checkForNewMessages();
  assert.equal(p.messages.filter(m => m.type === 'notification').length, 1);
});

test('read conversations remove their delivered notifications including after restart', () => {
  const p = page({threads: [{key: '/messages/t/1', unread: false}]});
  assert.ok(p.messages.some(m => m.type === 'read' && m.threadKeys.includes('/messages/t/1')));
});

test('attribute changes trigger a batched badge refresh', () => {
  const threads = [{key: '/messages/t/1', unread: true}];
  const p = page({tab: {getAttribute: () => 'true'}, threads});
  const observer = p.observers.find(o => o.options.attributes);
  assert.ok(observer, 'observe unread indicator class and selected tab attributes');
  threads[0].unread = false;
  observer.fn(); observer.fn();
  p.flush();
  assert.equal(p.messages.filter(m => m.type === 'badge').at(-1).count, 0);
});

test('returning to the window refreshes unread state', () => {
  const threads = [{key: '/messages/t/1', unread: true}];
  const p = page({tab: {getAttribute: () => 'true'}, threads});
  threads[0].unread = false;
  assert.equal(typeof p.listeners.focus, 'function');
  p.listeners.focus(); p.flush();
  assert.equal(p.messages.filter(m => m.type === 'badge').at(-1).count, 0);
});

test('filtered tabs do not replace the inbox count with an archive count', () => {
  const p = page({tab: {getAttribute: () => 'false'}, threads: []});
  assert.equal(p.messages.filter(m => m.type === 'badge').length, 0);
});

test('waits for Messenger startup before publishing unread state', () => {
  const p = page({ready: false, threads: [{key: '/messages/t/1', unread: true}]});
  assert.equal(p.messages.filter(m => m.type === 'badge').length, 0);
  p.setReady(true);
  p.observers[0].fn(); p.flush();
  assert.equal(p.messages.filter(m => m.type === 'badge').at(-1).count, 1);
  assert.equal(p.messages.filter(m => m.type === 'notification').length, 0);
});

test('signals page readiness once and only after the inbox exists', () => {
  const p = page({ready: false});
  assert.equal(p.messages.filter(m => m.type === 'ready').length, 0);
  p.setReady(true);
  p.goofy.refresh(); p.goofy.refresh();
  assert.equal(p.messages.filter(m => m.type === 'ready').length, 1);
});

test('refresh reuses the conversation scan for the badge count', () => {
  const p = page({threads: [{key: '/messages/t/1', unread: true}]});
  assert.equal(p.messages.find(m => m.type === 'badge')?.count, 1);
  assert.equal(p.queries.filter(q => q.includes('.x1spa7qu')).length, 0);
});

test('restored history page reports readiness without replaying notifications', () => {
  const p = page({threads: [{key: '/messages/t/1', unread: true}]});
  assert.equal(typeof p.listeners.pageshow, 'function');
  p.listeners.pageshow({persisted: true});
  assert.equal(p.messages.filter(m => m.type === 'ready').length, 2);
  assert.equal(p.messages.filter(m => m.type === 'notification').length, 0);
});
