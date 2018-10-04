Java.perform(function () {
  send("Starting hooks OWASP uncrackable1...");

  var sysexit = Java.use("java.lang.System");
  sysexit.exit.overload("int").implementation = function(var_0) {
    send("java.lang.System.exit(I)V  // We avoid exiting the application  :)");
  };

  var aes_decrypt = Java.use("sg.vantagepoint.a.a");
  aes_decrypt.a.overload("[B","[B").implementation = function(var_0,var_1) {
    send("sg.vantagepoint.a.a.a([B[B)[B   doFinal(enc)  // AES/ECB/PKCS7Padding");
    var ret = this.a.overload("[B","[B").call(this,var_0,var_1);

    flag = "";
    for (var i=0; i < ret.length; i++){
      flag += String.fromCharCode(ret[i]);
    }
    send("Decrypted flag: " + flag);
    return ret; //[B
  };


  // var mainactivity = Java.use("sg.vantagepoint.uncrackable1.MainActivity");
  // mainactivity.onStart.overload().implementation = function() {
  //   send("MainActivity.onStart() HIT!!!");
  //   var ret = this.onStart.overload().call(this);
  // };
  // //var mainactivity = Java.use("sg.vantagepoint.uncrackable1.MainActivity");
  // mainactivity.onCreate.overload("android.os.Bundle").implementation = function(var_0) {
  //   send("MainActivity.onCreate() HIT!!!");
  //   var ret = this.onCreate.overload("android.os.Bundle").call(this,var_0);
  // };
  //
  //
  // var activity = Java.use("android.app.Activity");
  // activity.onCreate.overload("android.os.Bundle").implementation = function(var_0) {
  //   send("Activity HIT!!!");
  //   var ret = this.onCreate.overload("android.os.Bundle").call(this,var_0);
  // };


  send("Hooks installed.");
});
