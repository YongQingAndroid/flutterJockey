# flutter_jockey

webView通信框架

## Getting Started

This project is a starting point for a Dart
[package](https://flutter.dev/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.

基于jcokeyJs协议和# webview_flutter实现

```
JockeyWebView(  /// 继承与Webview
    initialUrl: '',  
 jockeyHelper: JockeyHelper(  ///实例化JockeyHelper
        jockeyManagerCreated: (manager)=>{}, ///jockeyManager创建成功
        jockeyMap: (jockey) => {   ///注册jockey协议
              jockey.on("jockey", (payload, jockeyManager) {  
                /// jockey回调
                jockeyManager.sendData2Js("callJs", {});  /// 通过jockeyManager
 ///调用回调到js
                
 })  
            }),  
 // javascriptMode:  JavascriptMode.unrestricted,  
);
```
[jockeyJS文件下载](https://raw.githubusercontent.com/YongQingAndroid/flutterJockey/main/jockey.js)
