return {
  name = 'sockjs',
  version = '0.0.1',
  description = 'SockJS server implemented in Luvit',
  keywords = { 'websocket', 'sockjs', 'real-time', 'stack', 'luvit', 'libuv' },
  author = 'Vladimir Dronnikov <dronnikov@gmail.com>',
  dependencies = {
    websocket = 'https://github.com/dvv/luvit-websocket/zipball/master',
    --app = 'https://github.com/dvv/luvit-app/zipball/master',
  },
}
