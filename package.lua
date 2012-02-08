return {
  name = 'sockjs',
  version = '0.0.1',
  description = 'SockJS server implemented in Luvit',
  keywords = { 'websocket', 'sockjs', 'real-time', 'stack', 'luvit', 'libuv' },
  author = 'Vladimir Dronnikov <dronnikov@gmail.com>',
  dependencies = {
    app = 'https://github.com/dvv/luvit-app/zipball/master',
    static = 'https://github.com/dvv/luvit-static/zipball/master',
    websocket = 'https://github.com/dvv/luvit-websocket/zipball/master',
    uuid = 'https://github.com/dvv/luvit-uuid/zipball/master',
  },
}
