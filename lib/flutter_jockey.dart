library flutter_jockey;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';

class JockeyExecutor {
  Function call;
  String key;

  JockeyExecutor({required this.key, required this.call});
}

class JockeyBuilder {
  late ValueChanged<JockeyController> jockeyMap;
  late JockeyHelper jockeyHelper;
  Completer<JockeyHelper> ?_completer;
  JockeyBuilder({required ValueChanged<JockeyController> jockeyMap}) {
    jockeyHelper = JockeyHelper(jockeyMap: jockeyMap);
  }
  Future<JockeyHelper> create() async{
    _completer = new Completer();
    return _completer!.future;
  }
  void setWebViewController(WebViewController? webViewController) {
    jockeyHelper.webCreate(webViewController!);
    _completer!.complete(jockeyHelper);
  }
}

class JockeyManager {
  var _map = Map<String, JockeyExecutor>();
  int messageId = 0;
  WebViewController? webViewController;
  BuildContext? buildContext;

  JockeyManager();

  void on(String key, JockeyCallback jockeyCallback) {
    _map[key] = JockeyExecutor(call: jockeyCallback, key: '');
  }

  parseUrl(String urlDecode) {
    urlDecode = Uri.decodeComponent(urlDecode);
    Uri uri = Uri.parse(urlDecode);
    String host = uri.host;
    String query = Uri.decodeComponent(uri.query);
    if (host.endsWith("event")) {
      ///仅处理event
      JockeyBean jockeyBean = JockeyBean(query);
      if (_map.containsKey(jockeyBean.rootJson!['type'])) {
        try {
          var _exe = _map[jockeyBean.rootJson!['type']];
          _exe!.call(jockeyBean.payload, this);
        } catch (e) {
          print(e);
        }
      } else if (_map.containsKey(jockeyBean.payload!['action'])) {
        try {
          var _exe = _map[jockeyBean.payload!['action']];
          _exe!.call(jockeyBean.payload, this);
        } catch (e) {
          print(e);
        }
      }
      triggerCallbackOnWebView(jockeyBean.id);
    }
  }
  ///自动回调当前函数
  triggerCallbackOnWebView(int id){
    webViewController?.evaluateJavascript(
        "javascript:Jockey.triggerCallback('$id')");
  }
  sendData2Js(String callName, Object data) {
    sendString2Js(callName, jsonEncode(data));
  }

  sendString2Js(String callName, String data) {
    webViewController?.evaluateJavascript(
        "Jockey.trigger('$callName','$messageId','$data')");
    messageId++;
  }

  register(JockeyExecutor jockeyExecuter) {
    _map[jockeyExecuter.key] = jockeyExecuter;
  }
}

///定义事件包装类
class JockeyBean {
  Map<String, dynamic>? rootJson;
  Map<String, dynamic>? payload;
  int  id=-1;
  JockeyBean(String json) {
    print("jockey========$json");
    this.rootJson = jsonDecode(json);
    if (this.rootJson!['payload'] != null) {
      payload = this.rootJson!['payload'];
    }
    id=rootJson!['id'];
  }
}

///定义回调函数
typedef JockeyCallback = void Function(
    Map<String, dynamic> payload, JockeyManager jockeyManager);

class JockeyController {
  late Map<String, JockeyExecutor> _jockeyMap;

  JockeyController(Map<String, JockeyExecutor> map) {
    this._jockeyMap = map;
  }

  void on(String key, JockeyCallback jockeyCallback) {
    _jockeyMap[key] = JockeyExecutor(call: jockeyCallback, key: '');
  }
}

// ignore: must_be_immutable
class JockeyWebView extends WebView {
  late JockeyHelper jockeyHelper;

  JockeyWebView(
      {required JockeyHelper jockeyHelper,
        Key? key,
        WebViewCreatedCallback? onWebViewCreated,
        String? initialUrl,
        PageStartedCallback? onPageStarted,
        JavascriptMode javascriptMode = JavascriptMode.disabled,
        PageFinishedCallback? onPageFinished,
        NavigationDelegate? navigationDelegate,
        PageLoadingCallback? onProgress,
        Set<JavascriptChannel>? javascriptChannels,
        bool gestureNavigationEnabled = false,
        bool allowsInlineMediaPlayback = false,
        WebResourceErrorCallback? onWebResourceError,
        AutoMediaPlaybackPolicy initialMediaPlaybackPolicy =
            AutoMediaPlaybackPolicy.require_user_action_for_all_media_types,
        String? userAgent})
      : assert(javascriptMode != null),
        assert(initialMediaPlaybackPolicy != null),
        assert(allowsInlineMediaPlayback != null),
        super(
          key: key,
          onWebViewCreated: jockeyHelper
              .setHookCreatedCallback(onWebViewCreated)
              ._createdCallback,
          initialUrl: initialUrl,
          javascriptChannels: javascriptChannels,
          onWebResourceError: onWebResourceError,
          gestureNavigationEnabled: gestureNavigationEnabled,
          navigationDelegate: jockeyHelper
              .setHookNavigationDelegate(navigationDelegate)
              ._navigationDelegate,
          onPageStarted: onPageStarted,
          javascriptMode: javascriptMode,
          onPageFinished: onPageFinished,
          onProgress: onProgress,
          userAgent: userAgent,
          allowsInlineMediaPlayback: allowsInlineMediaPlayback,
          initialMediaPlaybackPolicy: initialMediaPlaybackPolicy);
}

class JockeyHelper {
  late ValueChanged<JockeyController> jockeyMap;
  ValueChanged<JockeyManager>? jockeyManagerCreated;
  late JockeyController jockeyController;
  late WebViewCreatedCallback _createdCallback;
  WebViewCreatedCallback? _hookCreatedCallback;
  NavigationDelegate? _hookNavigationDelegate;
  late NavigationDelegate _navigationDelegate;

  // WebViewController? _webViewController;
  late JockeyManager _jockeyManager;

  JockeyHelper({required this.jockeyMap, this.jockeyManagerCreated}) {
    _navigationDelegate = (request) => _hookUrl(request);
    _createdCallback = (viewController) => webCreate(viewController);
    this._jockeyManager = JockeyManager();
    this.jockeyMap(new JockeyController(this._jockeyManager._map));
  }

  JockeyHelper setHookCreatedCallback(WebViewCreatedCallback? callback) {
    this._hookCreatedCallback = callback!;
    return this;
  }

  JockeyHelper setHookNavigationDelegate(NavigationDelegate? callback) {
    this._hookNavigationDelegate = callback;
    return this;
  }

  webCreate(WebViewController viewController) {
    // this._webViewController = viewController;
    _hookCreatedCallback!(viewController);
    this._jockeyManager.webViewController = viewController;
    if(jockeyManagerCreated!=null)
      jockeyManagerCreated!(this._jockeyManager);
  }

  FutureOr<NavigationDecision> _hookUrl(NavigationRequest request) {
    String url = request.url;
    var result = judgeUrl(url);
    if (result != null) return result;
    if (_hookNavigationDelegate == null) {
      return NavigationDecision.navigate;
    } else {
      return _hookNavigationDelegate!(request);
    }
  }

  NavigationDecision? judgeUrl(String url) {
    if (url.contains("jockey")) {
      _jockeyManager.parseUrl(url);
      return NavigationDecision.prevent;
    }
  }
}
