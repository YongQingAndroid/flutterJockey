## 0.0.1

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
